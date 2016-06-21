//
//  KSNNetworkAFNetworking.h
//  KSNNetworkClient
//
//  Created by Sergey Kovalenko on 11/17/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSNNetworkClient.h"
#import <AFNetworking/AFNetworking.h>

FOUNDATION_EXPORT NSString * KSNQueryStringFromParameters(NSDictionary *parameters);

@interface KSNNetworkAFNetworking : NSObject <KSNNetworkBackingFramework>

@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

@end
