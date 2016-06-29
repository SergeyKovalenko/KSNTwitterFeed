//
//  KSNGroupedDataSourceTest.m
//
//  Created by Sergey Kovalenko on 11/2/16.
//  Copyright (c) 2016. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <KSNDataSource/KSNGroupedDataSource.h>

#define KSNIndexPath(X, Y) [NSIndexPath indexPathForRow:Y inSection:X]

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

@interface KSNGroupedDataSourceTest : XCTestCase

@property (nonatomic, strong) KSNGroupedDataSource *testDataSource;
@end

@interface KSNTestItem : NSObject

- (instancetype)initWithName:(NSString *)name lastName:(NSString *)lastName;
@property (nonatomic, copy, readonly) NSString *firstName;
@property (nonatomic, copy, readonly) NSString *lastName;

@end

@implementation KSNTestItem

- (instancetype)initWithName:(NSString *)name lastName:(NSString *)lastName
{
    self = [super init];
    if (self)
    {
        _firstName = [name copy];
        _lastName = [lastName copy];
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    }
    if (!other || ![[other class] isEqual:[self class]])
    {
        return NO;
    }

    KSNTestItem *otherItem = other;

    return [otherItem.firstName isEqualToString:self.firstName] && [otherItem.lastName isEqualToString:self.lastName];
}

- (NSUInteger)hash
{
    return [self.firstName hash] ^ [self.lastName hash];
}

- (NSString *)debugDescription
{
    return [super debugDescription];
}

- (NSString *)description
{
    return [self.firstName stringByAppendingFormat:@" %@", self.lastName];
}

@end

#define KSNItem(N, L) [[KSNTestItem alloc] initWithName:[@(N) description] lastName:[@(L) description]]

@implementation KSNGroupedDataSourceTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testDataSource = [[KSNGroupedDataSource alloc] initWithSectionKeyPath:@"firstName"
                                                               sectionMapBlock:^id <NSCopying>(id item) {
                                                                   return item;
                                                               }
                                                               sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
                                                                                 [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]
                                                          sectionTitleMapBlock:^NSString *(KSNTestItem *item) {
                                                              return item.firstName;
                                                          }];

    NSMutableArray *items = [NSMutableArray array];
    ksn_block_apply(5, ^(NSUInteger i) {
        ksn_block_apply(5, ^(NSUInteger j) {
            [items addObject:KSNItem(i, j)];
        });
    });

    [self.testDataSource addItems:items];
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

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 0)], KSNItem(0, 0));
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(4, 4)], KSNItem(4, 4));
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(3, 2)], KSNItem(3, 2));

    XCTAssertEqual(self.testDataSource.count, 25);

    XCTAssertEqualObjects([self.testDataSource indexPathOfItem:KSNItem(3, 2)], KSNIndexPath(3, 2));
}

- (void)testAddMoreItems
{
    [self.testDataSource addItems:@[KSNItem(0, 7),
                                    KSNItem(5, 0),
                                    KSNItem(5, 4),
                                    KSNItem(7, 0)]];

    XCTAssertEqual([self.testDataSource numberOfSections], 7);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 6);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:5], 2);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:6], 1);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(0, 5)], KSNItem(0, 7));
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(5, 1)], KSNItem(5, 4));
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(6, 0)], KSNItem(7, 0));

    XCTAssertEqual(self.testDataSource.count, 29);

    XCTAssertEqualObjects([self.testDataSource indexPathOfItem:KSNItem(7, 0)], KSNIndexPath(6, 0));
}

- (void)testRemoveItems
{
    [self.testDataSource removeItemsAtIndexPaths:@[KSNIndexPath(0, 0),
                                                   KSNIndexPath(4, 4),
                                                   KSNIndexPath(3, 2)]];
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 4);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:4], 4);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:3], 4);
    XCTAssertEqual(self.testDataSource.count, 22);
}

- (void)testRemoveAllItems
{
    [self.testDataSource removeAllItems];
    XCTAssertEqual(self.testDataSource.count, 0);

    [self.testDataSource addItems:@[KSNItem(0, 7),
                                    KSNItem(5, 0),
                                    KSNItem(5, 4),
                                    KSNItem(7, 0)]];

    XCTAssertEqual(self.testDataSource.count, 4);

    XCTAssertEqual([self.testDataSource numberOfItemsInSection:0], 1);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:1], 2);
    XCTAssertEqual([self.testDataSource numberOfItemsInSection:2], 1);

    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(1, 0)], KSNItem(5, 0));
    XCTAssertEqualObjects([self.testDataSource itemAtIndexPath:KSNIndexPath(1, 1)], KSNItem(5, 4));
}

- (void)testObservation
{
    id listenerMock = OCMProtocolMock(@protocol(KSNDataSourceObserver));
    //    [listenerMock setExpectationOrderMatters:YES];
    [self.testDataSource addChangeObserver:listenerMock];

    OCMExpect([listenerMock dataSourceBeginUpdates:self.testDataSource]);

    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:[OCMArg any]
                           atIndexPath:KSNIndexPath(0, 5)
                         forChangeType:KSNDataSourceChangeTypeInsert
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:[OCMArg any]
                           atIndexPath:KSNIndexPath(5, 0)
                         forChangeType:KSNDataSourceChangeTypeInsert
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:[OCMArg any]
                           atIndexPath:KSNIndexPath(5, 1)
                         forChangeType:KSNDataSourceChangeTypeInsert
                          newIndexPath:[OCMArg isNil]]);
    OCMExpect([listenerMock dataSource:self.testDataSource
                       didChangeObject:[OCMArg any]
                           atIndexPath:KSNIndexPath(6, 0)
                         forChangeType:KSNDataSourceChangeTypeInsert
                          newIndexPath:[OCMArg isNil]]);

    OCMExpect([listenerMock dataSource:self.testDataSource didChange:KSNDataSourceChangeTypeInsert atSectionIndex:5]);
    OCMExpect([listenerMock dataSource:self.testDataSource didChange:KSNDataSourceChangeTypeInsert atSectionIndex:6]);

    OCMExpect([listenerMock dataSourceEndUpdates:self.testDataSource]);

    [self.testDataSource addItems:@[KSNItem(0, 7),
                                    KSNItem(5, 0),
                                    KSNItem(5, 4),
                                    KSNItem(7, 0)]];

    OCMVerifyAll(listenerMock);
}
@end
