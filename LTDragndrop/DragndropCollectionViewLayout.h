//
//  DragndropCollectionViewLayout.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DragndropCollectionViewLayout : UICollectionViewLayout <UIGestureRecognizerDelegate>

/**
Size of one item (dragndrop card)
*/
@property (nonatomic) CGSize itemSize;

/**
Space between the items (dragndrop cards)
*/
@property (nonatomic) CGFloat interItemSpacingY;

/**
Number of columns in one row
*/
@property (nonatomic) NSInteger numberOfColumns;

/**
Scrolling speed during dragndrop card to other section
*/
@property (assign, nonatomic) CGFloat scrollingSpeed;

/**
Space from edges of the screen when scroll begins
*/
@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;


@property (strong, nonatomic, readonly) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (strong, nonatomic, readonly) UIPanGestureRecognizer *panGestureRecognizer;

@end

@protocol DragndropCollectionViewDataSource <UICollectionViewDataSource>
@optional

- (void)collectionView:(UICollectionView *)collectionView willMoveToIndexPath:(NSIndexPath *)toIndexPath andReplace:(BOOL)replace;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;

@end

@protocol DragndropCollectionViewLayout <UICollectionViewDelegateFlowLayout>
@optional

- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end