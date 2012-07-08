// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import "CDLCEncryptionInfo.h"

// This is used on iOS.

@implementation CDLCEncryptionInfo

- (id)initWithDataCursor:(CDMachOFileDataCursor *)cursor;
{
    if ((self = [super initWithDataCursor:cursor])) {
        encryptionInfoCommand.cmd = [cursor readInt32];
        encryptionInfoCommand.cmdsize = [cursor readInt32];
        
        encryptionInfoCommand.cryptoff = [cursor readInt32];
        encryptionInfoCommand.cryptsize = [cursor readInt32];
        encryptionInfoCommand.cryptid = [cursor readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)cmd;
{
    return encryptionInfoCommand.cmd;
}

- (uint32_t)cmdsize;
{
    return encryptionInfoCommand.cmdsize;
}

- (uint32_t)cryptoff;
{
    return encryptionInfoCommand.cryptoff;
}

- (uint32_t)cryptsize;
{
    return encryptionInfoCommand.cryptsize;
}

- (uint32_t)cryptid;
{
    return encryptionInfoCommand.cryptid;
}

- (BOOL)isEncrypted;
{
    return encryptionInfoCommand.cryptid != 0;
}

@end
