//
//  KSNTwitterAPI.h
//  Pods
//
//  Created by Sergey Kovalenko on 6/23/16.
//
//

#import <Foundation/Foundation.h>

@class KSNTwitterSocialAdapter;
@class RACSignal;
@class RACScheduler;

@protocol KSNTwitterResponseDeserializer <NSObject>

- (id)parseJSON:(id)json error:(NSError **)pError;

@end

@interface KSNTwitterAPI : NSObject

- (instancetype)initWithSocialAdapter:(KSNTwitterSocialAdapter *)socialAdapter;

- (RACSignal *)userTimelineWithDeserializer:(id <KSNTwitterResponseDeserializer>)deserializer;

@end
