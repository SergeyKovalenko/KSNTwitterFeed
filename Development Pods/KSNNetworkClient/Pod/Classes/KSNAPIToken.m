//
// Created by Sergey Kovalenko on 2/5/16.
//

#import "KSNAPIToken.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "KSNNetworkRequest.h"

@interface KSNAPIToken ()

@property (nonatomic, copy, readwrite) NSString *tokenString;
@property (nonatomic, readwrite) NSDictionary *httpHeaderData;
@end

@implementation KSNAPIToken

static KSNAPIToken *placeholder;

+ (NSDictionary *)propertyKeyMap
{
    return @{@keypath(placeholder, tokenString) : @"token"};
}

- (NSDictionary *)httpHeaderData
{
    return self.tokenString.length ? @{@"Authorization" : [NSString stringWithFormat:@"Bearer %@", self.tokenString]} : nil;
}

- (KSNNetworkRequest *)signRequest:(KSNNetworkRequest *)request
{
    NSMutableDictionary *headers = [request.httpHeaders mutableCopy];
    [headers addEntriesFromDictionary:[self httpHeaderData]];
    request.httpHeaders = headers;
    return request;
}

@end