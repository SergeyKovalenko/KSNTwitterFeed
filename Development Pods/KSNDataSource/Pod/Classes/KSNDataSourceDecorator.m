//
//  KSNDataSourceDecorator.m
//
//  Created by Sergey Kovalenko on 5/14/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNDataSourceDecorator.h"
#import <KSNObservable/KSNObservable.h>

#pragma clang diagnostic ignored "-Wprotocol"

@interface KSNDataSourceDecorator ()

@property (nonatomic, strong) KSNObservable *observable;
@property (nonatomic, strong, readwrite) id <KSNDataSource> dataSource;

@end

@implementation KSNDataSourceDecorator

- (id)initWithDataSource:(id <KSNDataSource>)dataSource
{
    self.dataSource = dataSource;
    self.observable = [[KSNObservable alloc] initWithProtocol:@protocol(KSNDataSourceObserver)];
    [self.dataSource addChangeObserver:self];
    return self;
}

- (void)dealloc
{
    [self.dataSource removeChangeObserver:self];
    [self removeAllChangeObservers];
}

#pragma mark - WKDataSourceObserver

- (void)dataSourceBeginNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceBeginNetworkUpdate:self];
}

- (void)dataSourceEndNetworkUpdate:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceEndNetworkUpdate:self];
}

- (void)dataSourceRefreshed:(id <KSNDataSource>)dataSource userInfo:(NSDictionary *)userInfo
{
    [self.notifyProxy dataSourceRefreshed:self userInfo:userInfo];
}

- (void)dataSourceBeginUpdates:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceBeginUpdates:self];
}

- (void)dataSourceEndUpdates:(id <KSNDataSource>)dataSource
{
    [self.notifyProxy dataSourceEndUpdates:self];
}

- (void)dataSource:(id <KSNDataSource>)dataSource
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(KSNDataSourceChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    [self.notifyProxy dataSource:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
}

- (void)dataSource:(id <KSNDataSource>)dataSource didChange:(KSNDataSourceChangeType)change atSectionIndex:(NSInteger)sectionIndex
{
    [self.notifyProxy dataSource:self didChange:change atSectionIndex:sectionIndex];
}

- (void)dataSource:(id <KSNDataSource>)dataSource updateFailedWithError:(NSError *)error
{
    [self.notifyProxy dataSource:self updateFailedWithError:error];
}

- (void)   dataSource:(id <KSNDataSource>)dataSource
selectItemAtIndexPath:(NSIndexPath *)indexPath
             scrollTo:(UITableViewScrollPosition)scrollTo
             animated:(BOOL)animated
{
    [self.notifyProxy dataSource:self selectItemAtIndexPath:indexPath scrollTo:scrollTo animated:animated];
}

- (void)dataSource:(id <KSNDataSource>)dataSource deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self.notifyProxy dataSource:self deselectItemAtIndexPath:indexPath animated:animated];
}

- (id <KSNDataSourceObserver>)notifyProxy
{
    return (id) _observable;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.dataSource];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [(id) self.dataSource methodSignatureForSelector:sel];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [super conformsToProtocol:aProtocol] || [self.dataSource conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [self.dataSource respondsToSelector:aSelector];
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

@end
