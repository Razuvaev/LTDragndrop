//
//  DragndropTableViewHeader.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "DragndropTableViewHeader.h"

@interface DragndropTableViewHeader()

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation DragndropTableViewHeader

#pragma mark - Lifecycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:220/255. green:220/255. blue:220/255. alpha:1.0]];
        [self addGestureRecognizer:self.tap];
        [self setupUI];
    }
    return self;
}

#pragma mark - SetupUI
- (void)setupUI {
    [self addSubview:self.headerLabel];
}

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc] init];
        [_headerLabel setTextColor:[UIColor blackColor]];
        [_headerLabel setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
        [_headerLabel setUserInteractionEnabled:YES];
    }
    return _headerLabel;
}

- (UITapGestureRecognizer *)tap {
    if (!_tap) {
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    }
    return _tap;
}

#pragma mark - Actions
- (void)tapAction {
    [self.delegate sectionTapped:_currentSection];
}

#pragma mark - Setters
- (void)setHeaderLabelWithSection:(NSInteger)section {
    [_headerLabel setText:[NSString stringWithFormat:@"%li section", section]];
    [self layoutSubviews];
}

#pragma mark - Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    [_headerLabel sizeToFit];
    [_headerLabel setFrame:CGRectMake(self.frame.size.width/2 - _headerLabel.frame.size.width/2, self.frame.size.height/2 - _headerLabel.frame.size.height/2, _headerLabel.frame.size.width, _headerLabel.frame.size.height)];
}

@end
