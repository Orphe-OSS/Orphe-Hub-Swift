//
//  OSCServerExceptionHandler.m
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/18.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

#import "ObjC_Exception.h"

@implementation ObjC_Exception

+ (BOOL)catchExceptionWithTryBlock:(__attribute__((noescape)) void(^ _Nonnull)())tryBlock error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    @try {
        tryBlock();
        return YES;
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:-9999 userInfo:exception.userInfo];
        return NO;
    }
}

@end
