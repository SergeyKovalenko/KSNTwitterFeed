//
// Created by Sergey Kovalenko on 6/22/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RACSignal;

@protocol WKSocialAdapter <NSObject>

@property (nonatomic, copy, readonly) NSString *socialAdapterName;

/// Returns a hot signal which immediately starts login flow. Next value would depends on specific implementation.
- (RACSignal *)startUserSession;

/// Returns a hot signal which immediately clears a user session. Sends complete or error
- (RACSignal *)endUserSession;

/// Returns a session info object based (instance class would depend on specific social adapter implementation) or nil if no active sessions
- (nullable id)userSession;

///// Returns a hot signal which immediately starts posting flow. Next value would depends on specific implementation.
///// message - The message text. Cannot be nil.
///// message - The web link URL. Can be nil.
///// message - The file URL for the user generated content. Can be nil.
//- (RACSignal *)postMessage:(NSString *)message linkURL:(nullable NSURL *)linkURL mediaURL:(nullable NSURL *)mediaURL;

@end

@interface KSNSocialAdapter : NSObject <WKSocialAdapter>

- (instancetype)initWithSocialAdapterName:(NSString *)socialAdapterName;

@end

NS_ASSUME_NONNULL_END