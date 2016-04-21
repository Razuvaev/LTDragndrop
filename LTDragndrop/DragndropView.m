//
//  DragndropView.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "DragndropView.h"

#import "DragndropCollectionViewCell.h"

static NSInteger numberOfSections = 7; //rows in collectionView

static NSString *dragndropCellIdentifier = @"dragndropCell";

@interface DragndropView ()

@property (nonatomic, strong) DragndropCollectionViewLayout *layout;

@end

@implementation DragndropView
#pragma mark - Lifecycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        _numberOfItemsInSection = 4;
        [self setupUI];
    }
    return self;
}

#pragma mark - setupUI
- (void)setupUI {
    [self addSubview:self.CV];
}

- (UICollectionView *)CV {
    if (!_CV) {
        _CV = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:self.layout];
        [_CV setDelegate:self];
        [_CV setDataSource:self];
        [_CV setBounces:YES];
        [_CV setShowsHorizontalScrollIndicator:NO];
        [_CV setScrollsToTop:NO];
        [_CV registerClass:[DragndropCollectionViewCell class] forCellWithReuseIdentifier:dragndropCellIdentifier];
        [_CV setBackgroundColor:[UIColor colorWithRed:245/255. green:245/255. blue:245/255. alpha:1.0]];
    }
    return _CV;
}

- (DragndropCollectionViewLayout *)layout {
    if (!_layout) {
        _layout = [[DragndropCollectionViewLayout alloc] init];
        [_layout setNumberOfColumns:_numberOfItemsInSection];
    }
    return _layout;
}

#pragma mark - CollectionView delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return numberOfSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _numberOfItemsInSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DragndropCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:dragndropCellIdentifier forIndexPath:indexPath];
    [cell setupCellWithType:white];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    DragndropCollectionViewCell *cell = (DragndropCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.25 animations:^{
        [cell setAlpha:0.5];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    DragndropCollectionViewCell *cell = (DragndropCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.25 animations:^{
        [cell setAlpha:1.0];
    }];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    DragndropCollectionViewCell *cell = (DragndropCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.currentType == empty) {
        return NO;
    }
    return YES;
}

#pragma mark - Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    [_CV setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

@end
