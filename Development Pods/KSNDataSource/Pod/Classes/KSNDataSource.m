//
//  KSNDataSource.m
//
//  Created by Sergey Kovalenko on 10/30/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "KSNDataSource.h"
#import "KSNUtils/KSNDebug.h"
#import <KSNObservable/KSNObservable.h>

@interface KSNDataSource ()

@property (nonatomic, strong) KSNObservable *observable;
@end

@implementation KSNDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _observable = [[KSNObservable alloc] initWithProtocol:@protocol(KSNDataSourceObserver)];
        _observable.notificationQueue = dispatch_get_main_queue();
    }
    return self;
}

- (id <KSNDataSourceObserver>)notifyProxy
{
    return (id) _observable;
}

- (void)dealloc
{
    [self removeAllChangeObservers];
}

#pragma mark - KSNDataSource

- (NSUInteger)numberOfSections
{
    KSN_REQUIRE_OVERRIDE;
    return 0;
}

- (NSUInteger)numberOfItemsInSection:(NSUInteger)sectionIndex
{
    KSN_REQUIRE_OVERRIDE;
    return 0;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

- (NSUInteger)count
{
    KSN_REQUIRE_OVERRIDE;
    return 0;
}

- (NSIndexPath *)indexPathOfItem:(id)item
{
    KSN_REQUIRE_OVERRIDE;
    return nil;
}

- (void)removeItemsAtIndexPaths:(NSArray *)indexPaths
{
    KSN_REQUIRE_OVERRIDE;
}

- (BOOL)isPaginationSupported
{
    return NO;
}

#pragma mark - Add / Remove Observer

- (void)addChangeObserver:(id <KSNDataSourceObserver>)observer
{
    [self.observable addListener:observer];
}

- (void)removeChangeObserver:(id <KSNDataSourceObserver>)observer
{
    [self.observable removeListener:observer];
}

- (void)removeAllChangeObservers
{
    [self.observable removeAllListeners];
}

#pragma mark - Public

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.notifyProxy dataSource:self selectItemAtIndexPath:indexPath scrollTo:UITableViewScrollPositionNone animated:NO];
}

@end
