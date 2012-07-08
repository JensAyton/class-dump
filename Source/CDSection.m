// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDSection.h"

#include <mach-o/loader.h>
#import "CDFatFile.h"
#import "CDMachOFile.h"
#import "CDLCSegment32.h"

@implementation CDSection
{
    NSString *segmentName;
    NSString *sectionName;
    
    NSData *data;
    BOOL hasLoadedData;
}

// Just to resolve multiple different definitions...
- (id)init;
{
    if ((self = [super init])) {
        segmentName = nil;
        sectionName = nil;
        
        data = nil;
        hasLoadedData = NO;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> segment; '%@', section: '%-16s'",
            NSStringFromClass([self class]), self,
            segmentName, [sectionName UTF8String]];
}

#pragma mark -

@synthesize segmentName;
@synthesize sectionName;

@synthesize data;

- (NSData *)data;
{
    [self loadData];

    return data;
}

@synthesize hasLoadedData;

- (void)loadData;
{
    // Impelement in subclasses
}

- (void)unloadData;
{
    if (self.hasLoadedData) {
        self.hasLoadedData = NO;
        self.data = nil;
    }
}

- (NSUInteger)addr;
{
    // Implement in subclasses.
    return 0;
}

- (NSUInteger)size;
{
    // Implement in subclasses.
    return 0;
}

- (CDMachOFile *)machOFile;
{
    // Implement in subclass (for now).
    return nil;
}

- (BOOL)containsAddress:(NSUInteger)address;
{
    // implement in subclasses.
    return NO;
}

- (NSUInteger)fileOffsetForAddress:(NSUInteger)address;
{
    // implement in subclasses.
    return 0;
}

@end
