//
// Created by Sergey Kovalenko on 2/5/16.
//

#import <Foundation/Foundation.h>
#import "KSNNetworkAPI.h"

@interface KSNNetworkAPIStub : NSProxy

+ (instancetype)errorStubWithRealAPI:(id)api error:(NSError *)error;
+ (instancetype)stubWithRealAPI:(id)api selectorToResponseObjectMap:(id (^)(SEL, NSArray *))mapBlock;

@property (nonatomic, assign) NSTimeInterval responseDelay;
@property (nonatomic, strong) id api;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy) id (^mapBlock)(SEL, NSArray *);

@end

@interface KSNNetworkAPI (Stubbing)

- (instancetype)stub; // emulate successful response
- (instancetype)stubWithError:(NSError *)error; // emulate error response, when error is nil unexpected response error will be send

@end

