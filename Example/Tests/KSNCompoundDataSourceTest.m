//
//  KSNCompoundDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNCompoundDataSource.h>
#import <KSNDataSource/KSNArrayDataSource.h>

#undef KSNASSERT
#define KSNASSERT(condition) NSAssert((condition), @"Invalid parameter not satisfying: %s", #condition)

#undef KSNASSERTMSG
#define KSNASSERTMSG(condition, desc) NSAssert((condition), #desc, #condition)

#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

@interface KSNCompoundDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNCompoundDataSource *flatCompoundDataSource;
@property (nonatomic, strong) KSNCompoundDataSource *sectionalCompoundDataSource;
@end

@implementation KSNCompoundDataSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    KSNArrayDataSource *array1 = [[KSNArrayDataSource alloc] initWithItems:@[@0,
                                                                             @1,
                                                                             @2]];
    KSNArrayDataSource *array2 = [[KSNArrayDataSource alloc] initWithItems:@[@3,
                                                                             @4,
                                                                             @5]];
    KSNArrayDataSource *array3 = [[KSNArrayDataSource alloc] initWithItems:@[@6,
                                                                             @7,
                                                                             @8,
                                                                             @9]];

    self.flatCompoundDataSource = [KSNCompoundDataSource flatDataSourceWithSubdataSources:@[array1,
                                                                                            array2,
                                                                                            array3]];
    self.sectionalCompoundDataSource = [KSNCompoundDataSource sectionDataSourceWithSubdataSources:@[array1,
                                                                                                    array2,
                                                                                                    array3]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.flatCompoundDataSource = nil;
    self.sectionalCompoundDataSource = nil;
}

- (void)testFlatDataSourceInfo
{
    XCTAssertEqual(self.flatCompoundDataSource.count, 10);
    XCTAssertEqual(self.flatCompoundDataSource.numberOfSections, 1);
    XCTAssertEqual([self.flatCompoundDataSource numberOfItemsInSection:0], 10);

    for (NSUInteger i = 0; i < [self.flatCompoundDataSource numberOfItemsInSection:0]; ++i)
    {
        NSNumber *number = [self.flatCompoundDataSource itemAtIndexPath:KSNIndexPath(i, 0)];
        XCTAssertEqualObjects(number, @(i));
    }
}

- (void)testFlatDataSourceMutation
{
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
//    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.flatCompoundDataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.flatCompoundDataSource]);

    OCMExpect([dataSourceObserver dataSource:self.flatCompoundDataSource
                             didChangeObject:@99
                                 atIndexPath:KSNIndexPath(10, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.flatCompoundDataSource
                             didChangeObject:@111
                                 atIndexPath:KSNIndexPath(11, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.flatCompoundDataSource
                             didChangeObject:@222
                                 atIndexPath:KSNIndexPath(12, 0)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);

    OCMExpect([dataSourceObserver dataSourceEndUpdates:self.flatCompoundDataSource]);

    KSNArrayDataSource *arrayDataSource = [self.flatCompoundDataSource.subdataSources lastObject];
    [arrayDataSource insertItems:@[@99,
                                   @111,
                                   @222]
            atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(arrayDataSource.count, 3)]];

    OCMVerifyAll(dataSourceObserver);
}

- (void)testSectionalDataSourceInfo
{
    XCTAssertEqual(self.sectionalCompoundDataSource.count, 10);
    XCTAssertEqual(self.sectionalCompoundDataSource.numberOfSections, 3);
    XCTAssertEqual([self.sectionalCompoundDataSource numberOfItemsInSection:0], 3);
    XCTAssertEqual([self.sectionalCompoundDataSource numberOfItemsInSection:1], 3);
    XCTAssertEqual([self.sectionalCompoundDataSource numberOfItemsInSection:2], 4);

    int count = 0;
    for (NSUInteger j = 0; j < [self.sectionalCompoundDataSource numberOfSections]; ++j)
    {
        for (NSUInteger i = 0; i < [self.sectionalCompoundDataSource numberOfItemsInSection:j]; ++i)
        {
            NSNumber *number = [self.sectionalCompoundDataSource itemAtIndexPath:KSNIndexPath(i, j)];
            XCTAssertEqualObjects(number, @(count));
            count++;
        }
    }
}

- (void)testSectionalDataSourceMutation
{
    id dataSourceObserver = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    //    [dataSourceObserver setExpectationOrderMatters:YES];
    [self.sectionalCompoundDataSource addChangeObserver:dataSourceObserver];

    OCMExpect([dataSourceObserver dataSourceBeginUpdates:self.sectionalCompoundDataSource]);

    OCMExpect([dataSourceObserver dataSource:self.sectionalCompoundDataSource
                             didChangeObject:@99
                                 atIndexPath:KSNIndexPath(4, 2)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.sectionalCompoundDataSource
                             didChangeObject:@111
                                 atIndexPath:KSNIndexPath(5, 2)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);
    OCMExpect([dataSourceObserver dataSource:self.sectionalCompoundDataSource
                             didChangeObject:@222
                                 atIndexPath:KSNIndexPath(6, 2)
                               forChangeType:KSNDataSourceChangeTypeInsert
                                newIndexPath:[OCMArg isNil]]);

    OCMExpect([dataSourceObserver dataSourceEndUpdates:self.sectionalCompoundDataSource]);

    KSNArrayDataSource *arrayDataSource = [self.sectionalCompoundDataSource.subdataSources lastObject];
    [arrayDataSource insertItems:@[@99,
                                   @111,
                                   @222]
            atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(arrayDataSource.count, 3)]];

    OCMVerifyAll(dataSourceObserver);
}

@end
