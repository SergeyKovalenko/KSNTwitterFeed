//
//  KSNCollapsibleDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNArrayDataSource.h>

#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

@interface KSNArrayDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNArrayDataSource *dataSource;
@end

@implementation KSNArrayDataSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _dataSource = [[KSNArrayDataSource alloc] initWithItems:@[@1,
                                                              @2,
                                                              @3,
                                                              @4,
                                                              @5,
                                                              @6,
                                                              @7,
                                                              @8]];
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
        XCTAssertEqualObjects([self.dataSource itemAtIndexPath:KSNIndexPath(i, 0)], @(i + 1));
    }
}

- (void)testMutation
{
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.dataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.dataSource]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:@1
                                 atIndexPath:KSNIndexPath(0, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:@4
                                 atIndexPath:KSNIndexPath(3, 0)
                               forChangeType:KSNDataSourceChangeTypeRemove
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.dataSource
                             didChangeObject:@8
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
