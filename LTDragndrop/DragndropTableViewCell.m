//
//  DragndropTableViewCell.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "DragndropTableViewCell.h"

static const CGFloat dragndropViewHeight = 120*7;

@implementation DragndropTableViewCell

#pragma mark - Lifecycle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - setupUI
- (void)setupUI {
    [self.contentView addSubview:self.dragndropView];
}

- (DragndropView *)dragndropView {
    if (!_dragndropView) {
        _dragndropView = [[DragndropView alloc] init];
    }
    return _dragndropView;
}

#pragma mark - Setters
- (void)setNumberOfItemsInSection:(NSInteger)numberOfItemsInSection {
    _numberOfItemsInSection = numberOfItemsInSection;
    [_dragndropView setNumberOfItemsInSection:numberOfItemsInSection];
}

#pragma mark - Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    [_dragndropView setFrame:CGRectMake(0, 0, self.frame.size.width, dragndropViewHeight)];
}

#pragma mark - Actions
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
