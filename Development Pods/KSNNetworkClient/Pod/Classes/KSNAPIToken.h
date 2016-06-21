//
// Created by Sergey Kovalenko on 2/5/16.
//

#import <Foundation/Foundation.h>

@class KSNNetworkRequest;

@protocol KSNAPIToken <NSObject>

- (KSNNetworkRequest *)signRequest:(KSNNetworkRequest *)request;
@end


@interface KSNAPIToken : NSObject <KSNAPIToken>

@property (nonatomic, copy, readonly) NSString *tokenString;

@property (nonatomic, readonly) NSDictionary *httpHeaderData;

@end


