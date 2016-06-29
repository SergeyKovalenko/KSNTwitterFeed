//
//  KSNCollapsibleDataSource.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNCollapsibleDataSource.h>
#import <KSNDataSource/KSNCollapsibleComponent.h>

#define TC(VALUE) [[KSNCollapsibleComponent alloc] initWithValue:VALUE]
#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

@interface KSNCollapsibleDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNCollapsibleDataSource *dataSource;
@end

@implementation KSNCollapsibleDataSourceTest

- (KSNComponent *)createTree
{
    KSNCollapsibleComponent *component = TC(@0);
    component.collapsed = NO;
    KSNCollapsibleComponent *c1 = TC(@1);
    c1.collapsed = NO;
    KSNCollapsibleComponent *c2 = TC(@2);
    c2.collapsed = NO;
    KSNCollapsibleComponent *c3 = TC(@3);
    c3.collapsed = NO;
    KSNCollapsibleComponent *c4 = TC(@4);
    c4.collapsed = NO;
    KSNCollapsibleComponent *c5 = TC(@5);
    c5.collapsed = NO;
    KSNCollapsibleComponent *c6 = TC(@6);
    c6.collapsed = NO;
    KSNCollapsibleComponent *c7 = TC(@7);
    c7.collapsed = NO;

    [component addComponent:c1];
    [component addComponent:c4];
    [component addComponent:c6];

    [c1 addComponent:c2];
    [c1 addComponent:c3];

    [c4 addComponent:c5];

    [c6 addComponent:c7];
    return component;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _dataSource = [[KSNCollapsibleDataSource alloc] initWithComponent:[self createTree]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _dataSource = nil;
    [super tearDown];
}

- (void)testCollapse
{
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.dataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.dataSource]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(5, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(3, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(2, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSourceEndUpdates:self.dataSource]);

    [self.dataSource collapseItemAtIndexPaths:@[KSNIndexPath(1, 0),
                                                KSNIndexPath(4, 0)]];
    XCTAssertEqual(self.dataSource.count, 5);
    OCMVerifyAll(dataSourceObserver);
}

- (void)testExpand
{
    [self.dataSource collapseItemAtIndexPaths:@[KSNIndexPath(1, 0),
                                                KSNIndexPath(4, 0)]];

    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.dataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.dataSource]);

    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(2, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(3, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(5, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);

    OCMExpect([dataSourceObserver dataSourceEndUpdates:self.dataSource]);

    [self.dataSource expandItemAtIndexPaths:@[KSNIndexPath(1, 0),
                                              KSNIndexPath(2, 0)]];

    OCMVerifyAll(dataSourceObserver);
}

#define CC(VALUE) [[KSNCollapsibleComponent alloc] initWithValue:VALUE]
#define WKApply(N, B) for (NSUInteger i = 0; i < N; ++i) {B(i);}

- (KSNCollapsibleDataSource *)createMessagesDataSource
{
    KSNCollapsibleComponent *component = CC(@"");
    component.collapsed = NO;
    WKApply(7, (^(NSUInteger i) {
        NSString *name = [NSString stringWithFormat:@"Subject Name %lu", (unsigned long) i];
        KSNCollapsibleComponent *subject = CC(name);
        subject.collapsed = NO;
        [component addComponent:subject];
        WKApply(5, (^(NSUInteger i) {
            NSString *name = [NSString stringWithFormat:@"Email Conversation %lu", (unsigned long) i];
            KSNCollapsibleComponent *conversation = CC(name);
            conversation.collapsed = NO;
            [subject addComponent:conversation];
        }))
    }))
    

    return [[KSNCollapsibleDataSource alloc] initWithComponent:component];
}

- (void)testCollapseExpand
{
    KSNCollapsibleDataSource *dataSource = [self createMessagesDataSource];
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    [dataSourceObserver setExpectationOrderMatters:YES];
    [dataSource addChangeObserver:dataSourceObserver];
    KSNComponent *component = [dataSource valueForKey:@"component"];

    XCTAssertEqual(dataSource.count, 43);
    XCTAssertEqual(component.count, 43);

    void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
        /* code that reads and modifies the invocation object */
        NSLog(@"efwf %@", invocation);
    };
    [[[dataSourceObserver stub] andDo:theBlock] dataSource:[OCMArg any]
                                           didChangeObject:nil
                                               atIndexPath:[OCMArg any]
                                             forChangeType:KSNDataSourceChangeTypeRemove
                                              newIndexPath:[OCMArg any]];

    [dataSource collapseItemAtIndexPaths:@[KSNIndexPath(1, 0)]];

    XCTAssertEqual(dataSource.count, 38);
    XCTAssertEqual(component.count, 38);
}
@end
