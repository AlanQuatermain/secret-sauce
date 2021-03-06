/*
 *     Generated by class-dump 3.3.1 (64 bit).
 *
 *     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2009 by Steve Nygard.
 */

#import "NSObject.h"

@interface VMUTraceRecord : NSObject
{
    unsigned int seqnum;
    unsigned int type;
    unsigned long long address;
    unsigned long long argument;
    unsigned int depth;
    unsigned long long *frames;
}

- (id)initWithLoggingRecord:(CDStruct_7523a67d *)arg1 forTask:(unsigned int)arg2;
- (id)initWithBacktrace:(id)arg1 forTask:(unsigned int)arg2;
- (id)initWithTraceRecord:(id)arg1 withDepth:(unsigned int)arg2;
- (id)initWithTraceRecord:(id)arg1;
- (unsigned int)seqnum;
- (unsigned int)threadID;
- (unsigned int)type;
- (unsigned long long)address;
- (unsigned long long)argument;
- (unsigned int)depth;
- (unsigned long long *)frames;

@end

