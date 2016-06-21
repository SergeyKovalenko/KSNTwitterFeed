//
//  KSNNetworkRequest.m
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNNetworkRequest.h"

@interface KSNNetworkRequest ()
@property (nonatomic, strong, readwrite) NSString *urlString;
@end

@implementation KSNNetworkRequest

- (instancetype)initWithUrlString:(NSString *)urlString
{
    self = [super init];
    if (self)
    {
        self.urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.httpMethod = KSN_HTTP_METHOD_GET;
    }
    return self;
}

+ (instancetype)getRequestWithUrlString:(NSString *)urlString
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_GET;
    return req;
}

+ (instancetype)getRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params {
	KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
	req.httpMethod = KSN_HTTP_METHOD_GET;
	req.params = params;
	return req;
}

+ (instancetype)postRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_POST;
    req.params = params;
    return req;
}

+ (instancetype)putRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_PUT;
    req.params = params;
    return req;
}

+ (instancetype)postRequestWithUrlString:(NSString *)urlString fileURL:(NSURL *)fileURL
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_POST;
    req.fileURL = fileURL;
    return req;
}

+ (instancetype)putRequestWithUrlString:(NSString *)urlString fileURL:(NSURL *)fileURL
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_PUT;
    req.fileURL = fileURL;
    return req;
}

+ (instancetype)deleteRequestWithUrlString:(NSString *)urlString
{
    KSNNetworkRequest *req = [[KSNNetworkRequest alloc] initWithUrlString:urlString];
    req.httpMethod = KSN_HTTP_METHOD_DELETE;
    return req;
}

@end
