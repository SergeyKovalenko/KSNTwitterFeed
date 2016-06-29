//
//  KSNSectionedDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNSectionedDataSource.h>

#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

FOUNDATION_STATIC_INLINE void ksn_block_apply(NSUInteger n, void (^block)(NSUInteger i))
{
    if (block)
    {
        for (NSUInteger i = 0; i < n; ++i)
        {
            block(i);
        }
    }
}

@interface KSNSectionedDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNSectionedDataSource *testDataSource;
@end

@implementation KSNSectionedDataSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testDataSource = [[KSNSectionedDataSource alloc] init];

    ksn_block_apply(5, ^(NSUInteger i) {
        NSMutableArray *section = [NSMutableArray array];
        ksn_block_apply(5, ^(NSUInteger j) {
            [section addObject:[NSString stringWithFormat:@"%lu - %lu", (unsigned long) i, (unsigned long) j]];
        });
        [self.testDataSource addSection:section];
    });
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.testDataSource = nil;
    [super tearDown];
}

- (void)testDataSourceProtocolsImmutableMethods
{
    XCTAssertEqual([self.testDataSource numberOfSections], 5);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:4], 5);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 0");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)], @"4 - 4");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 2)], @"2 - 3");

    XCTAssertEqual(self.testDataSource.count, 25);

    XCTAssertEqualObjects([self.testDataSource indexPathOfItem:@"2 - 3"], KSNIndexPath(3, 2));
}

- (void)testDataSourceProtocolsRemoveMethodsWithoutSectionChange
{
    [self.testDataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                                   KSNIndexPath(4, 4),
                                                   KSNIndexPath(3, 2)]];

    XCTAssertEqual([self.testDataSource numberOfSections], 5);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 4);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 4);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:4], 4);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 1");
//    XCTAssertThrows([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)]);
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 2)], @"2 - 4");

    XCTAssertEqual(self.testDataSource.count, 22);
}

- (void)testDataSourceProtocolsRemoveMethodsWithSectionChange
{
    [self.testDataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                                   KSNIndexPath(1, 0),
                                                   KSNIndexPath(2, 0),
                                                   KSNIndexPath(3, 0),
                                                   KSNIndexPath(4, 0)]];

    XCTAssertEqual([self.testDataSource numberOfSections], 4);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 5);
//    XCTAssertThrows([self.testDataSource numberOfItemsInSection:4]);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"1 - 0");
//    XCTAssertThrows([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)]);
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 3)], @"4 - 3");

    XCTAssertEqual(self.testDataSource.count, 20);
}

- (void)testSectionedDataSourceAddMutationMethods
{
    [self.testDataSource addSection:@[@"5 - 0",
                                      @"5 - 1",
                                      @"5 - 3",
                                      @"5 - 4"]];

    XCTAssertEqual([self.testDataSource numberOfSections], 6);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:5], 4);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 0");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)], @"4 - 4");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 2)], @"2 - 3");

    XCTAssertEqual(self.testDataSource.count, 29);
}

- (void)testSectionedDataSourceAddMutationMethodsInSpecificSection
{
    [self.testDataSource addItems:@[@"5 - 0",
                                    @"5 - 1",
                                    @"5 - 3",
                                    @"5 - 4"]
            inSection:2];

    XCTAssertEqual([self.testDataSource numberOfSections], 5);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 5);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 9);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:4], 5);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 0");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)], @"4 - 4");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(7, 2)], @"5 - 3");

    XCTAssertEqual(self.testDataSource.count, 29);
}

- (void)testObservation
{
    id listenerMock = OCMProtocolMock(@protocol(KSNDataSourceObserver));
//    [listenerMock setExpectationOrderMatters:YES];
    [self.testDataSource addChangeObserver:listenerMock];

    OCMExpect([listenerMock dataSourceBeginUpdates:self.testDataSource]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:@"0 - 0"
                           atIndexPath:KSNIndexPath(0, 0)
                         forChangeType:KSNDataSourceChangeTypeRemove
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:@"4 - 4"
                           atIndexPath:KSNIndexPath(4, 4)
                         forChangeType:KSNDataSourceChangeTypeRemove
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:@"2 - 3"
                           atIndexPath:KSNIndexPath(3, 2)
                         forChangeType:KSNDataSourceChangeTypeRemove
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSourceEndUpdates:self.testDataSource]);

    [self.testDataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                                   KSNIndexPath(4, 4),
                                                   KSNIndexPath(3, 2)]];
    OCMVerifyAll(listenerMock);
}
@end
