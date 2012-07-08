// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2011 Steve Nygard.

#import "CDLoadCommand.h"

@interface CDLCEncryptionInfo : CDLoadCommand
{
    struct encryption_info_command encryptionInfoCommand;
}

@property (readonly) uint32_t cryptoff;
@property (readonly) uint32_t cryptsize;
@property (readonly) uint32_t cryptid;

@property (readonly) BOOL isEncrypted;

@end
