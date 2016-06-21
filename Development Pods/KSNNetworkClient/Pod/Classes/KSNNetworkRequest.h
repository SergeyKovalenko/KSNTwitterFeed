//
//  KSNNetworkRequest.h
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const KSN_HTTP_METHOD_GET = @"GET";
static NSString *const KSN_HTTP_METHOD_POST = @"POST";
static NSString *const KSN_HTTP_METHOD_DELETE = @"DELETE";
static NSString *const KSN_HTTP_METHOD_PUT = @"PUT";

@interface KSNNetworkRequest : NSObject

- (instancetype)initWithUrlString:(NSString *)urlString;
+ (instancetype)getRequestWithUrlString:(NSString *)urlString;
+ (instancetype)getRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params;
+ (instancetype)postRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params;
+ (instancetype)putRequestWithUrlString:(NSString *)urlString params:(NSDictionary *)params;

+ (instancetype)postRequestWithUrlString:(NSString *)urlString fileURL:(NSURL *)fileURL;
+ (instancetype)putRequestWithUrlString:(NSString *)urlString fileURL:(NSURL *)fileURL;
+ (instancetype)deleteRequestWithUrlString:(NSString *)urlString;

@property (nonatomic, strong, readonly) NSString *urlString;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSDictionary *httpHeaders;

@property (nonatomic, strong) NSDictionary *multipartFormData;
@property (nonatomic, strong) NSURL *fileURL;

@end
