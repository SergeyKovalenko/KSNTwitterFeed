//
//  KSNErrorHandler.h
//  KSNErrorHandler
//
//  Created by Sergey Kovalenko on 11/21/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_STATIC_INLINE BOOL KSNIsNetworkError(NSError *error)
{
    switch (error.code)
    {
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorHTTPTooManyRedirects:
        case NSURLErrorResourceUnavailable:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorRedirectToNonExistentLocation:
        case NSURLErrorInternationalRoamingOff:
        case NSURLErrorCallIsActive:
        case NSURLErrorDataNotAllowed:
        case NSURLErrorSecureConnectionFailed:
        case NSURLErrorCannotLoadFromNetwork:
        case NSURLErrorTimedOut:
            return YES;
            
        default:
            return NO;
    }
};

typedef BOOL (^KSNErrorHandlerBlock)(NSError *error);

@interface KSNErrorHandler : NSObject

@property (nonatomic, copy) KSNErrorHandlerBlock defaultErrorHandler;

@property (nonatomic, copy) KSNErrorHandlerBlock networkErrorHandler;

- (id)addErrorHandlerWithBlock:(KSNErrorHandlerBlock)handler forErrorDomain:(NSString *)errorDomain errorCode:(NSInteger)errorCode;

- (id)addErrorHandlerWithBlock:(KSNErrorHandlerBlock)handler forErrorDomain:(NSString *)errorDomain;

- (void)removeErrorHandler:(id)errorHandler;

- (BOOL)handleError:(NSError *)error;

@end
