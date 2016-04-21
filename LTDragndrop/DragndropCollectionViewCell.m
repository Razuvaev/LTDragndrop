//
//  DragndropCollectionViewCell.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "DragndropCollectionViewCell.h"

static const CGFloat leftMargin = 10;
static const CGFloat borderWidth = 1;

@interface DragndropCollectionViewCell ()

@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic, strong) UIView *rightBorder;

@end

@implementation DragndropCollectionViewCell

#pragma mark - Lifecycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:242/255. green:242/255. blue:242/255. alpha:1.0]];
        [self setupUI];
        
        [self.layer setRasterizationScale:[UIScreen mainScreen].scale];
        [self.layer setShouldRasterize:YES];
    }
    return self;
}

#pragma makr - setupUI
- (void)setupUI {
    [self addSubview:self.bottomBorder];
    [self addSubview:self.rightBorder];
}

- (UIView *)bottomBorder {
    if (!_bottomBorder) {
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - borderWidth, self.frame.size.width, borderWidth)];
        [_bottomBorder setBackgroundColor:[UIColor darkGrayColor]];
    }
    return _bottomBorder;
}

- (UIView *)rightBorder {
    if (!_rightBorder) {
        _rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - borderWidth, 0, borderWidth, self.frame.size.height)];
        [_rightBorder setBackgroundColor:[UIColor darkGrayColor]];
    }
    return _rightBorder;
}

#pragma mark - Setters
- (void)setupCellWithType:(cellType)cellType {
    _currentType = cellType;
    [self.contentView setAlpha:cellType];
}

#pragma mark - Layout
- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
