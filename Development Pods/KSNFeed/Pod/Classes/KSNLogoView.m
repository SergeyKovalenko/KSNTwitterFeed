//
//  KSNLogoView.m

//
//  Created by Sergey Kovalenko on 1/26/15.
//  Copyright (c) 2015. All rights reserved.
//

#import "KSNLogoView.h"

@implementation KSNLogoView

- (instancetype)init
{
//#pragma message("TODO: (Sergey) !!!")
    self = [super initWithImage:[UIImage new]];
    if (self)
    {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }

    return self;
}

@end
