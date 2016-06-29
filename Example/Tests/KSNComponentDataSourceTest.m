//
//  KSNComponentDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNComponentDataSource.h>

#define TC(VALUE) [[KSNComponent alloc] initWithValue:VALUE]
#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

@interface KSNComponentDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNComponentDataSource *dataSource;
@end

@implementation KSNComponentDataSourceTest

- (KSNComponent *)createTree
{
    KSNComponent *component = TC(@0);
    KSNComponent *c1 = TC(@1);
    KSNComponent *c2 = TC(@2);
    KSNComponent *c3 = TC(@3);
    KSNComponent *c4 = TC(@4);
    KSNComponent *c5 = TC(@5);
    KSNComponent *c6 = TC(@6);
    KSNComponent *c7 = TC(@7);

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
    _dataSource = [[KSNComponentDataSource alloc] initWithComponent:[self createTree]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _dataSource = nil;
    [super tearDown];
}

- (void)testDataSource
{
    // This is an example of a functional test case.
    XCTAssertEqual(self.dataSource.count, 8);
    XCTAssertEqual(self.dataSource.numberOfSections, 1);
    XCTAssertEqual([self.dataSource numberOfItemsInSection:0], 8);
    for (NSUInteger i = 0; i < [self.dataSource numberOfItemsInSection:0]; ++i)
    {
        KSNComponent *component = [self.dataSource itemAtIndexPath:KSNIndexPath(i, 0)];
        XCTAssertEqualObjects(component.value, @(i));
    }
}

- (void)testMutation
{
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.dataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.dataSource]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(0, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(3, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:[OCMArg any]
                                 atIndexPath:KSNIndexPath(7, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSourceEndUpdates:self.dataSource]);

    [self.dataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                               KSNIndexPath(3, 0),
                                               KSNIndexPath(7, 0)]];

    OCMVerifyAll(dataSourceObserver);
}

@end
