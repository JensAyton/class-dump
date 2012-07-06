// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-1998, 2000-2001, 2004-2012 Steve Nygard.

#import <Foundation/Foundation.h>

@class CDTypeController, CDTypeFormatter, CDTypeName;

@interface CDType : NSObject <NSCopying>

- (id)init;
- (id)initSimpleType:(int)typeCode;
- (id)initIDType:(CDTypeName *)name;
- (id)initIDTypeWithProtocols:(NSArray *)protocols;
- (id)initStructType:(CDTypeName *)name members:(NSArray *)members;
- (id)initUnionType:(CDTypeName *)name members:(NSArray *)members;
- (id)initBitfieldType:(int)bitfieldSize;
- (id)initArrayType:(CDType *)type count:(int)count;
- (id)initPointerType:(CDType *)type;
- (id)initFunctionPointerType;
- (id)initBlockType;
- (id)initModifier:(int)modifier type:(CDType *)type;

- (void)setUnderlyingType:(NSUInteger)underlyingWidth;

@property (strong) NSString *variableName;

@property (nonatomic, readonly) int type;
@property (readonly) BOOL isIDType;
@property (readonly) BOOL isNamedObject;
@property (readonly) BOOL isTemplateType;
@property (readonly) BOOL isGarbageCollectedType;
@property (readonly) BOOL isBitfieldType;

@property (nonatomic, readonly) CDType *subtype;
@property (nonatomic, readonly) CDTypeName *typeName;

@property (nonatomic, readonly) NSArray *members;

@property (nonatomic, readonly) int typeIgnoringModifiers;
@property (nonatomic, readonly) NSUInteger structureDepth;

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level;

@property (nonatomic, readonly) NSString *typeString;
@property (nonatomic, readonly) NSString *bareTypeString;
@property (nonatomic, readonly) NSString *reallyBareTypeString;
@property (nonatomic, readonly) NSString *keyTypeString;


- (BOOL)canMergeWithType:(CDType *)otherType;
- (void)mergeWithType:(CDType *)otherType;

@property (readonly) NSArray *memberVariableNames;
- (void)generateMemberNames;

// Phase 0
- (void)phase:(NSUInteger)phase registerTypesWithObject:(CDTypeController *)typeController usedInMethod:(BOOL)isUsedInMethod;
- (void)phase0RecursivelyFixStructureNames:(BOOL)flag;

// Phase 1
- (void)phase1RegisterStructuresWithObject:(CDTypeController *)typeController;

// Phase 2
- (void)phase2MergeWithTypeController:(CDTypeController *)typeController debug:(BOOL)phase2Debug;

// Phase 3
- (void)phase3RegisterMembersWithTypeController:(CDTypeController *)typeController;
- (void)phase3MergeWithTypeController:(CDTypeController *)typeController;

@end

extern BOOL global_shouldMangleTemplateTypes;
