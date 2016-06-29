//
//  KSNSectionsDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNSectionsDataSource.h>

#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:X inSection:Y]

static NSInteger KSNItemsInSection = 3;

@interface KSNSectionsDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNSectionsDataSource *testDataSource;

@end

@implementation KSNSectionsDataSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testDataSource = [[KSNSectionsDataSource alloc] initWithSectionItems:@[@"0 - 0",
                                                                                @"0 - 1",
                                                                                @"0 - 2",
                                                                                @"0 - 3"]
            numberOfItemsInSection:KSNItemsInSection];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.testDataSource = nil;
    [super tearDown];
}

- (void)testDataSourceProtocolsImmutableMethods
{
    XCTAssertEqual([self.testDataSource numberOfSections], 4);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], KSNItemsInSection);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:1], KSNItemsInSection);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:3], KSNItemsInSection);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 0");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(2, 1)], @"0 - 1");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(1, 3)], @"0 - 3");

    XCTAssertEqual(self.testDataSource.count, 4);

    XCTAssertEqualObjects([self.testDataSource indexPathOfItem:@"0 - 2"], KSNIndexPath(0, 2));
}

- (void)testDataSourceProtocolsRemoveMethods
{
    [self.testDataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                                   KSNIndexPath(0, 1),
                                                   KSNIndexPath(0, 2)]];

    XCTAssertEqual([self.testDataSource numberOfSections], 1);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 3);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 3");

    XCTAssertEqual(self.testDataSource.count, 1);
}

- (void)testSectionedDataSourceAddMutationMethods
{
//@[@"0 - 0", @"0 - 1", @"0 - 2", @"0 - 3"]

    [self.testDataSource insertItems:@[@"0 - 4",
                                       @"0 - 5",
                                       @"0 - 6"]
            atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(4, 3)]];
    XCTAssertEqual([self.testDataSource numberOfSections], 7);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:6], KSNItemsInSection);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], @"0 - 0");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)], @"0 - 4");
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 6)], @"0 - 6");

    XCTAssertEqual(self.testDataSource.count, 7);
}

- (NSIndexPath *)previousIndexPathForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0 && indexPath.row < [self.testDataSource numberOfItemsInSection:indexPath.section])
    {
        return [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    }
    else if (indexPath.row == 0 && indexPath.section > 0 && indexPath.section < [self.testDataSource numberOfSections])
    {
        NSInteger newSection = indexPath.section - 1;
        return [NSIndexPath indexPathForRow:[self.testDataSource numberOfItemsInSection:newSection] - 1 inSection:newSection];
    }
    return nil;
}

- (void)test
{
    //@[@"0 - 0", @"0 - 1", @"0 - 2", @"0 - 3"]

    XCTAssertNil([self previousIndexPathForIndexPath:KSNIndexPath(0, 0)]);
    XCTAssertEqualObjects([self previousIndexPathForIndexPath:KSNIndexPath(1, 0)], KSNIndexPath(0, 0));
    XCTAssertEqualObjects([self previousIndexPathForIndexPath:KSNIndexPath(2, 0)], KSNIndexPath(1, 0));
    XCTAssertEqualObjects([self previousIndexPathForIndexPath:KSNIndexPath(0, 1)], KSNIndexPath(2, 0));
    XCTAssertEqualObjects([self previousIndexPathForIndexPath:KSNIndexPath(2, 1)], KSNIndexPath(1, 1));
}

@end
