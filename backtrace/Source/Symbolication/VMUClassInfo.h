/*
 *     Generated by class-dump 3.3.1 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2009 by Steve Nygard.
 */

#import "NSObject.h"

@class NSString;

@interface VMUClassInfo : NSObject
{
    NSString *_className;
    NSString *_binaryName;
    NSString *_type;
}

+ (id)classInfoWithClassName:(id)arg1 binaryName:(id)arg2 type:(id)arg3;
- (id)initWithClassName:(id)arg1 binaryName:(id)arg2 type:(id)arg3;
- (void)dealloc;
- (unsigned long long)hash;
- (BOOL)isEqual:(id)arg1;
- (id)description;
- (id)className;
- (id)binaryName;
- (id)type;

@end
