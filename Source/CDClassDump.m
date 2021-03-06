// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDClassDump.h"

#import "CDFatArch.h"
#import "CDFatFile.h"
#import "CDLCDylib.h"
#import "CDMachOFile.h"
#import "CDObjectiveCProcessor.h"
#import "CDType.h"
#import "CDTypeFormatter.h"
#import "CDTypeParser.h"
#import "CDVisitor.h"
#import "CDLCSegment.h"
#import "CDTypeController.h"
#import "CDSearchPathState.h"

@interface CDClassDump ()
- (CDMachOFile *)machOFileWithID:(NSString *)anID;
@end

#pragma mark -

@implementation CDClassDump
{
    CDSearchPathState *searchPathState;
    
    BOOL shouldProcessRecursively;
    BOOL shouldSortClasses; // And categories, protocols
    BOOL shouldSortClassesByInheritance; // And categories, protocols
    BOOL shouldSortMethods;
    
    BOOL shouldShowIvarOffsets;
    BOOL shouldShowMethodAddresses;
    BOOL shouldShowHeader;
    
    NSRegularExpression *regularExpression;
    
    NSString *sdkRoot;
    NSMutableArray *machOFiles;
    NSMutableDictionary *machOFilesByID;
    NSMutableArray *objcProcessors;
    
    CDTypeController *typeController;
    
    CDArch targetArch;
}

- (id)init;
{
    if ((self = [super init])) {
        searchPathState = [[CDSearchPathState alloc] init];
        sdkRoot = nil;
        
        machOFiles = [[NSMutableArray alloc] init];
        machOFilesByID = [[NSMutableDictionary alloc] init];
        objcProcessors = [[NSMutableArray alloc] init];
        
        typeController = [[CDTypeController alloc] initWithClassDump:self];
        
        // These can be ppc, ppc7400, ppc64, i386, x86_64
        targetArch.cputype = CPU_TYPE_ANY;
        targetArch.cpusubtype = 0;
        
        shouldShowHeader = YES;
    }

    return self;
}

#pragma mark -

@synthesize searchPathState;
@synthesize shouldProcessRecursively;
@synthesize shouldSortClasses;
@synthesize shouldSortClassesByInheritance;
@synthesize shouldSortMethods;
@synthesize shouldShowIvarOffsets;
@synthesize shouldShowMethodAddresses;
@synthesize shouldShowHeader;

@synthesize regularExpression;

#pragma mark - Regular expression handling

- (BOOL)shouldShowName:(NSString *)name;
{
    if (self.regularExpression != nil) {
        NSTextCheckingResult *firstMatch = [self.regularExpression firstMatchInString:name options:0 range:NSMakeRange(0, [name length])];
        return firstMatch != nil;
    }

    return YES;
}

#pragma mark -

@synthesize sdkRoot;
@synthesize machOFiles;
@synthesize objcProcessors;
@synthesize targetArch;

- (BOOL)containsObjectiveCData;
{
    for (CDObjectiveCProcessor *processor in objcProcessors) {
        if ([processor hasObjectiveCData])
            return YES;
    }

    return NO;
}

- (BOOL)hasEncryptedFiles;
{
    for (CDMachOFile *machOFile in machOFiles) {
        if ([machOFile isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)hasObjectiveCRuntimeInfo;
{
    return self.containsObjectiveCData || self.hasEncryptedFiles;
}

@synthesize typeController;

- (BOOL)loadFile:(CDFile *)file;
{
    //NSLog(@"targetArch: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
    CDMachOFile *aMachOFile = [file machOFileWithArch:targetArch];
    //NSLog(@"aMachOFile: %@", aMachOFile);
    if (aMachOFile == nil) {
        fprintf(stderr, "Error: file doesn't contain the specified arch.\n\n");
        return NO;
    }

    // Set before processing recursively.  This was getting caught on CoreUI on 10.6
    assert([aMachOFile filename] != nil);
    [machOFiles addObject:aMachOFile];
    [machOFilesByID setObject:aMachOFile forKey:[aMachOFile filename]];

    if ([self shouldProcessRecursively]) {
        @try {
            for (CDLoadCommand *loadCommand in [aMachOFile loadCommands]) {
                if ([loadCommand isKindOfClass:[CDLCDylib class]]) {
                    CDLCDylib *aDylibCommand = (CDLCDylib *)loadCommand;
                    if ([aDylibCommand cmd] == LC_LOAD_DYLIB) {
                        [searchPathState pushSearchPaths:[aMachOFile runPaths]];
                        [self machOFileWithID:[aDylibCommand path]]; // Loads as a side effect
                        [searchPathState popSearchPaths];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            return NO;
        }
    }

    return YES;
}

#pragma mark -

- (void)processObjectiveCData;
{
    for (CDMachOFile *machOFile in machOFiles) {
        CDObjectiveCProcessor *aProcessor = [[[machOFile processorClass] alloc] initWithMachOFile:machOFile];
        [aProcessor process];
        [objcProcessors addObject:aProcessor];
    }
}

// This visits everything segment processors, classes, categories.  It skips over modules.  Need something to visit modules so we can generate separate headers.
- (void)recursivelyVisit:(CDVisitor *)visitor;
{
    [visitor willBeginVisiting];

    for (CDObjectiveCProcessor *processor in objcProcessors) {
        [processor recursivelyVisit:visitor];
    }

    [visitor didEndVisiting];
}

- (CDMachOFile *)machOFileWithID:(NSString *)anID;
{
    NSString *adjustedID = nil;
    NSString *executablePathPrefix = @"@executable_path";
    NSString *rpathPrefix = @"@rpath";

    if ([anID hasPrefix:executablePathPrefix]) {
        adjustedID = [anID stringByReplacingOccurrencesOfString:executablePathPrefix withString:searchPathState.executablePath];
    } else if ([anID hasPrefix:rpathPrefix]) {
        //NSLog(@"Searching for %@ through run paths: %@", anID, [searchPathState searchPaths]);
        for (NSString *searchPath in [searchPathState searchPaths]) {
            NSString *str = [anID stringByReplacingOccurrencesOfString:rpathPrefix withString:searchPath];
            //NSLog(@"trying %@", str);
            if ([[NSFileManager defaultManager] fileExistsAtPath:str]) {
                adjustedID = str;
                //NSLog(@"Found it!");
                break;
            }
        }
        if (adjustedID == nil) {
            adjustedID = anID;
            //NSLog(@"Did not find it.");
        }
    } else if (sdkRoot != nil) {
        adjustedID = [sdkRoot stringByAppendingPathComponent:anID];
    } else {
        adjustedID = anID;
    }

    CDMachOFile *aMachOFile = [machOFilesByID objectForKey:adjustedID];
    if (aMachOFile == nil) {
        NSData *data = [[NSData alloc] initWithContentsOfMappedFile:adjustedID];
        CDFile *aFile = [CDFile fileWithData:data filename:adjustedID searchPathState:searchPathState];

        if (aFile == nil || [self loadFile:aFile] == NO)
            NSLog(@"Warning: Failed to load: %@", adjustedID);

        aMachOFile = [machOFilesByID objectForKey:adjustedID];
        if (aMachOFile == nil) {
            NSLog(@"Warning: Couldn't load MachOFile with ID: %@, adjustedID: %@", anID, adjustedID);
        }
    }

    return aMachOFile;
}

- (void)appendHeaderToString:(NSMutableString *)resultString;
{
    // Since this changes each version, for regression testing it'll be better to be able to not show it.
    if (self.shouldShowHeader == NO)
        return;

    [resultString appendString:@"/*\n"];
    [resultString appendFormat:@" *     Generated by class-dump %s.\n", CLASS_DUMP_VERSION];
    [resultString appendString:@" *\n"];
    [resultString appendString:@" *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2012 by Steve Nygard.\n"];
    [resultString appendString:@" */\n\n"];

    if (self.sdkRoot != nil) {
        [resultString appendString:@"/*\n"];
        [resultString appendFormat:@" * SDK Root: %@\n", self.sdkRoot];
        [resultString appendString:@" */\n\n"];
    }
}

- (void)registerTypes;
{
    for (CDObjectiveCProcessor *processor in objcProcessors) {
        [processor registerTypesWithObject:typeController phase:0];
    }
    [typeController endPhase:0];

    [typeController workSomeMagic];
}

- (void)showHeader;
{
    if ([machOFiles count] > 0) {
        [[[machOFiles lastObject] headerString:YES] print];
    }
}

- (void)showLoadCommands;
{
    if ([machOFiles count] > 0) {
        [[[machOFiles lastObject] loadCommandString:YES] print];
    }
}

@end
