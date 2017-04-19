//
//  OSCServerExceptionHandler.h
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/18.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjC_Exception : NSObject
+ (BOOL)catchExceptionWithTryBlock:(__attribute__((noescape)) void(^ _Nonnull)())tryBlock error:(NSError * _Nullable __autoreleasing * _Nullable)error;
@end
