//
// Created by Sergey Kovalenko on 5/24/16.
// Copyright (c) 2016 Windmill. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
//#import <DTCoreText/DTCoreText.h>
#import "WMLNewsItemCellNode.h"
#import "MRKNewsItem.h"
#import "WMLStretchedTableViewNode.h"

@interface UIColor (Hex)

+ (UIColor *)wml_colorWithHex:(uint)hex alpha:(CGFloat)alpha;
+ (UIColor *)wml_colorWithHex:(uint)hex;
@end

@implementation UIColor (Hex)

+ (UIColor *)wml_colorWithHex:(uint)hex alpha:(CGFloat)alpha
{
    int b = hex & 0x0000FF;
    int g = ((hex & 0x00FF00) >> 8);
    int r = ((hex & 0xFF0000) >> 16);
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:alpha];
}

+ (UIColor *)wml_colorWithHex:(uint)hex
{
    return [UIColor wml_colorWithHex:hex alpha:1.0];
}
@end

@interface WMLTextNode : ASTextNode
@end

@implementation WMLTextNode

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
    [self.attributedText enumerateAttribute:NSAttachmentAttributeName
                                    inRange:NSMakeRange(0, self.attributedText.length)
                                    options:0
                                 usingBlock:^(NSTextAttachment *attachment, NSRange range, BOOL *stop) {
                                     if (attachment)
                                     {
                                         CGRect bounds = CGRectZero;
                                         CGFloat scale = constrainedSize.width / attachment.image.size.width;
                                         bounds.size.width = scale * attachment.image.size.width;
                                         bounds.size.height = scale * attachment.image.size.height;
                                         attachment.bounds = bounds;
                                     }
                                 }];
    return [super calculateSizeThatFits:constrainedSize];
}

@end

@interface WMLNewsItemCellNode ()

@property (nonatomic, strong) MRKNewsItem *newsItem;
@end

@implementation WMLNewsItemCellNode
{
    ASNetworkImageNode *_imageNode;
    ASTextNode *_titleLabel;
    ASTextNode *_subTitleLabel;
    ASTextNode *_textLabel;
    ASTextNode *_photoDescriptionLabel;
    WMLStretchedTableViewNode *_recomendedNode;
}

- (instancetype)initWithNewsItems:(MRKNewsItem *)newsItem
{
    self = [self init];
    if (self)
    {
        self.newsItem = newsItem;

        self.selectionStyle =  UITableViewCellSelectionStyleNone;
        _titleLabel = [[ASTextNode alloc] init];

        if (newsItem.name)
        {
            _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:newsItem.name
                                                                         attributes:[self textAttributesWithFont:[UIFont boldSystemFontOfSize:32.f]
                                                                                                        colorHex:0x5B5B5B]];
        }

        NSMutableAttributedString *attributedSubtitle = [[NSMutableAttributedString alloc] init];

        if (self.newsItem.date)
        {
            [attributedSubtitle appendAttributedString:[[NSAttributedString alloc] initWithString:[NSDateFormatter localizedStringFromDate:self.newsItem.date
                                                                                                                                 dateStyle:NSDateFormatterShortStyle
                                                                                                                                 timeStyle:NSDateFormatterShortStyle]
                                                                                       attributes:[self textAttributesWithFont:[UIFont systemFontOfSize:13.f]
                                                                                                                      colorHex:0x5B5B5B]]];
        }

        if (self.newsItem.categories.count)
        {
            NSString *categories = [self.newsItem.categories componentsJoinedByString:@", "];
            [attributedSubtitle appendAttributedString:[[NSAttributedString alloc] initWithString:[@"– " stringByAppendingString:categories]
                                                                                       attributes:[self textAttributesWithFont:[UIFont systemFontOfSize:13.f]
                                                                                                                      colorHex:0xA9A9A9]]];
        }

        _subTitleLabel = [[ASTextNode alloc] init];
        _subTitleLabel.maximumNumberOfLines = 1;
        _subTitleLabel.attributedText = attributedSubtitle;

        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.URL = self.newsItem.imageURL;
        _imageNode.layerBacked = YES;

        _textLabel = [[WMLTextNode alloc] init];
        if (self.newsItem.text)
        {
            __block NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithHTMLData:[self.newsItem.text dataUsingEncoding:NSUTF8StringEncoding]
                                                                                                   documentAttributes:nil];

            [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                                 options:0
                                              usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                                                  NSMutableDictionary *newAttributes = [attrs mutableCopy];

                                                  DTImageTextAttachment *attachment = [attrs valueForKey:NSAttachmentAttributeName];
                                                  if (attachment)
                                                  {
                                                      NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                                                      textAttachment.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:attachment.contentURL]];
                                                      newAttributes[NSAttachmentAttributeName] = textAttachment;
                                                  }

                                                  if ([attrs valueForKey:NSFontAttributeName])
                                                  {
                                                      [newAttributes addEntriesFromDictionary:[self textAttributesWithFont:[UIFont systemFontOfSize:15.f]
                                                                                                                  colorHex:0x666666]];
                                                  }

                                                  if ([attrs valueForKey:DTLinkAttribute])
                                                  {
                                                      [newAttributes removeObjectForKey:DTLinkAttribute];
                                                      [newAttributes removeObjectForKey:@"CTForegroundColor"];
                                                      [newAttributes removeObjectForKey:@"CTForegroundColorFromContext"];
                                                      [newAttributes removeObjectForKey:@"NSUnderline"];
                                                  }
                                                  [newAttributes removeObjectForKey:NSLinkAttributeName];

                                                  [newAttributes removeObjectForKey:NSStrokeColorAttributeName];

                                                  [attributedString setAttributes:newAttributes range:range];
                                              }];

            _textLabel.attributedText = attributedString;
        }

        _recomendedNode = [[WMLStretchedTableViewNode alloc] init];
        _recomendedNode.backgroundColor = [UIColor greenColor];
        _recomendedNode.spacingBefore = 155.f;
        _recomendedNode.spacingAfter = 15.f;
        // instead of adding everything addSubnode:
        self.usesImplicitHierarchyManagement = YES;
    }
    return self;
}

- (NSDictionary *)textAttributesWithFont:(UIFont *)font colorHex:(uint)hex
{
    return @{NSFontAttributeName            : font,
             NSForegroundColorAttributeName : [UIColor wml_colorWithHex:hex]};
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *verticalStack = [ASStackLayoutSpec verticalStackLayoutSpec];
    verticalStack.flexShrink = YES;
    verticalStack.spacing = 15;
    [verticalStack setChildren:@[_titleLabel,
                                 _subTitleLabel,
                                 _imageNode,
                                 _textLabel,
//                                 _recomendedNode
                                 ]];
    UIEdgeInsets insets = UIEdgeInsetsMake(15, 25, 10, 10);
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets child:verticalStack];
}

- (void)setSelected:(BOOL)selected
{
    if (self.selected != selected)
    {
        _recomendedNode.numberIfItems = arc4random_uniform(5);
    }
    [super setSelected:selected];

}

- (void)didLoad
{
    [super didLoad];
}

- (void)layoutDidFinish
{
    [super layoutDidFinish];
}

- (void)displayWillStart
{
    [super displayWillStart];
}

- (void)displayDidFinish
{
    [super displayDidFinish];
}

- (void)interfaceStateDidChange:(ASInterfaceState)newState fromState:(ASInterfaceState)oldState
{
    [super interfaceStateDidChange:newState fromState:oldState];
}

- (void)visibilityDidChange:(BOOL)isVisible
{
    [super visibilityDidChange:isVisible];
}

- (void)willEnterHierarchy
{
    [super willEnterHierarchy];
}

- (void)didExitHierarchy
{
    [super didExitHierarchy];
}

- (void)fetchData
{
    [super fetchData];
}

- (void)clearFetchedData
{
    [super clearFetchedData];
}

- (void)clearContents
{
    [super clearContents];
}

- (void)subnodeDisplayWillStart:(ASDisplayNode *)subnode
{
    [super subnodeDisplayWillStart:subnode];
}

- (void)subnodeDisplayDidFinish:(ASDisplayNode *)subnode
{
    [super subnodeDisplayDidFinish:subnode];
}

@end