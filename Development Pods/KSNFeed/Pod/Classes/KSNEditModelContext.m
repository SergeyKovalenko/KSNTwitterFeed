//
//  KSNEditModelContext.m
//
//  Created by Sergey Kovalenko on 2/10/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNEditModelContext.h"
#import "KSNObservable/KSNObservable.h"

NSString * const KSNEditModelContextOriginalModelKey = @"KSNEditModelContextOriginalModelKey";

@interface KSNEditModelContext ()

@property (nonatomic, strong) KSNObservable *observable;
@end

@implementation KSNEditModelContext

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.observable = [[KSNObservable alloc] initWithProtocol:@protocol(KSNEditModelContextObserver)];
    }
    
    return self;
}

- (id <KSNEditModelContextObserver>)contextObservation
{
    return (id <KSNEditModelContextObserver>) self.observable;
}

- (void)notifyChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo
{
    [self notifyWillChangeModels:models withEditType:editType userInfo:userInfo];
    [self notifyDidChangeModels:models withEditType:editType userInfo:userInfo];
}

- (void)notifyWillChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo
{
    [self.contextObservation editContext:self willChangeModels:models withEditType:editType userInfo:userInfo];
}

- (void)notifyDidChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo
{
    [self.contextObservation editContext:self didChangeModels:models withEditType:editType userInfo:userInfo];
}

- (void)notifyFailedWithError:(NSError *)error userInfo:(NSDictionary *)userInfo
{
    [self.contextObservation editContext:self failedWithError:error userInfo:userInfo];
}

- (void)addEditContextObserver:(id <KSNEditModelContextObserver>)observer
{
    [self.observable addListener:observer];
}

- (void)removeEditContextObserver:(id <KSNEditModelContextObserver>)observer
{
    [self.observable removeListener:observer];
}

- (void)removeAllEditContextObserver
{
    [self.observable removeAllListeners];
}

@end
