//
//  KSNSocialNetworksMediator.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/22/16.
//
//

#import <Foundation/Foundation.h>

@protocol WKSocialAdapter;
@class RACSignal;

NS_ASSUME_NONNULL_BEGIN

@interface KSNSocialNetworksMediator : NSObject

- (instancetype)initWithSocialAdapters:(NSArray <id <WKSocialAdapter>> *)socialAdapters;

/// Available social adapters by name
@property (nonatomic, readonly) NSDictionary <NSString *, id <WKSocialAdapter>> *availableAdapters;

/// Returns a hot signal which immediately starts login flow. Next value would depends on specific implementation of <WKSocialAdapter>.
/// socialAdapterName - The name of social adapter. Cannot be nil.
- (RACSignal *)startUserSessionWithSocialAdapterName:(NSString *)socialAdapterName;

/// Returns a hot signal which immediately clears a user session. Sends complete or error
/// socialAdapterName - The name of social adapter. Cannot be nil.
- (RACSignal *)endUserSessionWithSocialAdapterName:(NSString *)socialAdapterName;;

/// Returns a hot signal which immediately clears all user sessions. Sends complete or error
- (RACSignal *)endUserSessions;

/// Returns a session info object based (instance class would depend on specific social adapter implementation) or nil if no active sessions
/// socialAdapterName - The name of social adapter. Cannot be nil.
- (nullable id)userSessionWithSocialAdapterName:(NSString *)socialAdapterName;;

/// Returns a hot signal which immediately starts posting flow. Next value would depends on specific implementation  of <WKSocialAdapter>..
/// socialAdapterName - The name of social adapter. Cannot be nil.
- (RACSignal *)postMessage:(NSString *)message linkURL:(nullable NSURL *)linkURL mediaURL:(nullable NSURL *)mediaURL withSocialAdapterName:(NSString *)socialAdapterName;
@end

NS_ASSUME_NONNULL_END
