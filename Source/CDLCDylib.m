// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCDylib.h"

#import "CDFatFile.h"
#import "CDMachOFile.h"

static NSString *CDDylibVersionString(uint32_t version)
{
    return [NSString stringWithFormat:@"%d.%d.%d", version >> 16, (version >> 8) & 0xff, version & 0xff];
}

@implementation CDLCDylib
{
    struct dylib_command dylibCommand;
    NSString *path;
}

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        dylibCommand.cmd = [cursor readInt32];
        dylibCommand.cmdsize = [cursor readInt32];
        
        dylibCommand.dylib.name.offset = [cursor readInt32];
        dylibCommand.dylib.timestamp = [cursor readInt32];
        dylibCommand.dylib.current_version = [cursor readInt32];
        dylibCommand.dylib.compatibility_version = [cursor readInt32];
        
        NSUInteger length = dylibCommand.cmdsize - sizeof(dylibCommand);
        //NSLog(@"expected length: %u", length);
        
        path = [cursor readStringOfLength:length encoding:NSASCIIStringEncoding];
        //NSLog(@"path: %@", path);
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return dylibCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return dylibCommand.cmdsize;
}

@synthesize path;

- (uint32_t)timestamp;
{
    return dylibCommand.dylib.timestamp;
}

- (uint32_t)currentVersion;
{
    return dylibCommand.dylib.current_version;
}

- (uint32_t)compatibilityVersion;
{
    return dylibCommand.dylib.compatibility_version;
}

- (NSString *)formattedCurrentVersion;
{
    return CDDylibVersionString(self.currentVersion);
}

- (NSString *)formattedCompatibilityVersion;
{
    return CDDylibVersionString(self.compatibilityVersion);
}

#if 0
- (NSString *)extraDescription;
{
    return [NSString stringWithFormat:@"%@ (compatibility version %@, current version %@, timestamp %d [%@])",
                     self.path, CDDylibVersionString(self.compatibilityVersion), CDDylibVersionString(self.currentVersion),
                     self.timestamp, [NSDate dateWithTimeIntervalSince1970:self.timestamp]];
}
#endif

@end
