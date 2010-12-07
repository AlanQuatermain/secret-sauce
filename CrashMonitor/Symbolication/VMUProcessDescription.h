/*
 *     Generated by class-dump 3.3.1 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2009 by Steve Nygard.
 */

#import "NSObject.h"

@class NSArray, NSCalendarDate, NSDictionary, NSMutableArray, NSString;

@interface VMUProcessDescription : NSObject
{
    unsigned int _task;
    int _pid;
    struct _CSTypeRef _symbolicator;
    NSString *_userAppName;
    NSString *_processName;
    BOOL _processNameNeedsCorrection;
    NSString *_executablePath;
    BOOL _executablePathNeedsCorrection;
    unsigned long long _executableLoadAddress;
    int _cpuType;
    BOOL _isNative;
    BOOL _is64Bit;
    struct LSItemInfoRecord *_itemInfoRecord;
    NSDictionary *_lsApplicationInformation;
    NSMutableArray *_binaryImages;
    NSArray *_sortedBinaryImages;
    NSDictionary *_binaryImageHints;
    NSArray *_unreadableBinaryImagePaths;
    BOOL _binaryImagePostProcessingComplete;
    NSString *_parentProcessName;
    NSString *_parentExecutablePath;
    int _ppid;
    NSCalendarDate *_date;
    NSString *_internalError;
}

- (id)initWithPid:(int)arg1 orTask:(unsigned int)arg2;
- (double)_extractDyldInfoFromSymbolOwner:(struct _CSTypeRef)arg1 withNonContiguousMemory:(id)arg2;
- (unsigned long long)readAddressFromMemory:(id)arg1 atSymbol:(struct _CSTypeRef)arg2;
- (id)readStringFromMemory:(id)arg1 atAddress:(unsigned long long)arg2;
- (id)_readDataFromMemory:(id)arg1 atAddress:(unsigned long long)arg2 size:(unsigned long long)arg3;
- (id)_extractInfoPlistFromSymbolOwner:(struct _CSTypeRef)arg1 withNonContiguousMemory:(id)arg2;
- (void)_extractCrashReporterBinaryImageHintsFromSymbolOwner:(struct _CSTypeRef)arg1 withNonContiguousMemory:(id)arg2;
- (void)_extractBinaryImageInfoFromSymbolOwner:(struct _CSTypeRef)arg1;
- (id)date;
- (unsigned int)task;
- (int)pid;
- (int)cpuType;
- (id)processName;
- (id)processIdentifier;
- (id)displayName;
- (int)ppid;
- (id)parentExecutablePath;
- (id)parentProcessName;
- (id)lsApplicationInformation;
- (id)processVersionDictionary;
- (id)processVersion;
- (id)executablePath;
- (id)bundleIdentifier;
- (BOOL)isNative;
- (BOOL)is64Bit;
- (BOOL)isTranslated;
- (BOOL)isAppleApplication;
- (id)bundleLock;
- (id)binaryImages;
- (id)binaryImageDictionaryForAddress:(unsigned long long)arg1;
- (id)_cpuTypeDescription;
- (id)binaryImagesDescription;
- (id)_buildInfoDescription;
- (id)_systemVersionDescription;
- (id)processDescriptionHeader;
- (id)dateAndVersionDescription;
- (id)description;
- (void)dealloc;

@end
