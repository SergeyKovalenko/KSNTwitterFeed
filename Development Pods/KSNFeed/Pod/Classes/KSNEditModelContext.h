//
//  KSNEditModelContext.h

//
//  Created by Sergey Kovalenko on 2/10/15.
//  Copyright (c) 2015. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const KSNEditModelContextOriginalModelKey;

typedef NS_ENUM(NSInteger, KSNEditContextEditType)
{
    KSNEditContextEditTypeInsert,
    KSNEditContextEditTypeRemove,
    KSNEditContextEditTypeUpdate,
};

@protocol KSNEditModelContext;

@protocol KSNEditModelContextObserver <NSObject>

@optional

- (void)editContext:(id <KSNEditModelContext>)editContext willChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo;

- (void)editContext:(id <KSNEditModelContext>)editContext didChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo;

- (void)editContext:(id <KSNEditModelContext>)editContext failedWithError:(NSError *)error userInfo:(NSDictionary *)userInfo;

@end

@protocol KSNEditModelContext

- (void)notifyChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo;
- (void)notifyWillChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo;
- (void)notifyDidChangeModels:(NSArray *)models withEditType:(KSNEditContextEditType)editType userInfo:(NSDictionary *)userInfo;
- (void)notifyFailedWithError:(NSError *)error userInfo:(NSDictionary *)userInfo;

// Add/Remove observers
- (void)addEditContextObserver:(id <KSNEditModelContextObserver>)observer;
- (void)removeEditContextObserver:(id <KSNEditModelContextObserver>)observer;
- (void)removeAllEditContextObserver;
@end

@interface KSNEditModelContext : NSObject <KSNEditModelContext>

@end
