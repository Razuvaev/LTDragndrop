//
//  DragndropCollectionViewLayout.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "DragndropCollectionViewLayout.h"
#import "DragndropTableViewCell.h"
#import "DragndropCollectionViewCell.h"

#import <objc/runtime.h>

static NSString * const dragndropLayoutCellKind = @"dragndropCell";
static NSString * const kLXScrollingDirectionKey = @"kLXScrollingDirection";
static NSString * const collectionViewKeyPath = @"collectionView";

#ifndef CGGEOMETRY_SUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIView *)LX_snapshotView;

@end

@implementation UICollectionViewCell (TrainingPlanCollectionViewLayout)

- (UIView *)LX_snapshotView {
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:image];
    }
}

@end

@interface DragndropCollectionViewLayout ()

@property (nonatomic) NSInteger sourceCollectionViewTag;

@property (strong, nonatomic) UITableView *parentView;
@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;

@property (nonatomic, strong) NSDictionary *layoutInfo;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic, readonly) id<DragndropCollectionViewDataSource> dataSource;
@property (assign, nonatomic, readonly) id<DragndropCollectionViewLayout> delegate;

@end

@implementation DragndropCollectionViewLayout

#pragma mark - Lifecycle
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.itemSize = CGSizeMake(116, 120);
    self.interItemSpacingY = CGFLOAT_MIN;
    self.numberOfColumns = 3;
    
    _scrollingSpeed = 600.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (id<DragndropCollectionViewDataSource>)dataSource {
    return (id<DragndropCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<DragndropCollectionViewLayout>)delegate {
    return (id<DragndropCollectionViewLayout>)self.collectionView.delegate;
}

#pragma mark - Properties
- (void)setItemSize:(CGSize)itemSize {
    if (CGSizeEqualToSize(_itemSize, itemSize)) return;
    
    _itemSize = itemSize;
    
    [self invalidateLayout];
}

- (void)setInterItemSpacingY:(CGFloat)interItemSpacingY {
    if (_interItemSpacingY == interItemSpacingY) return;
    
    _interItemSpacingY = interItemSpacingY;
    
    [self invalidateLayout];
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns {
    if (_numberOfColumns == numberOfColumns) return;
    
    _numberOfColumns = numberOfColumns;
    
    [self invalidateLayout];
}

- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (self.currentView) {
        if (!self.displayLink.paused) {
            LXScrollingDirection oldDirection = [self.displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
            
            if (direction == oldDirection) {
                return;
            }
        }
        
        [self invalidatesScrollTimer];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
        self.displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };
        
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

#pragma mark - Layout

- (void)prepareLayout {
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    for (NSInteger section = 0; section < sectionCount; section ++) {
        NSInteger itemsCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemsCount; item ++) {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForTrainingPlanAtIndexPath:indexPath];
            
            cellLayoutInfo[indexPath] = itemAttributes;
        }
    }
    
    newLayoutInfo[dragndropLayoutCellKind] = cellLayoutInfo;
    self.layoutInfo = newLayoutInfo;
    
    if (!_longPressGestureRecognizer) {
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleLongPress:)];
        _longPressGestureRecognizer.delegate = self;
        
        // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
        // by enforcing failure dependency so that they doesn't clash.
        for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
            }
        }
        
        [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    }
    
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handlePanGesture:)];
        _panGestureRecognizer.delegate = self;
        [self.collectionView addGestureRecognizer:_panGestureRecognizer];
    }
    
    if (!_parentView) {
        _parentView = (UITableView *)[[[[[self.collectionView superview] superview] superview] superview] superview];
    }
}

- (void)invalidateLayoutIfNecessary:(BOOL)replace withNewIndexPath:(NSIndexPath *)newIndexPath {
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:willMoveToIndexPath:andReplace:)]) {
        [self.dataSource collectionView:self.collectionView willMoveToIndexPath:newIndexPath andReplace:replace];
    }
}

#pragma mark - Gesture handlers
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == 2) {
        return;
    }
    NSIndexPath *parentViewIndexPath = [_parentView indexPathForRowAtPoint:[sender locationInView:_parentView]];
    
    DragndropTableViewCell *parentCell = (DragndropTableViewCell *)[_parentView cellForRowAtIndexPath:parentViewIndexPath];
//    if ([parentCell isKindOfClass:[DragndropTableViewCell class]]) {
//        [self returnCellToStartPosition];
//        return;
//    }
    
    UICollectionView *currentCollectionView = parentCell.dragndropView.CV;
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            _sourceCollectionViewTag = currentCollectionView.tag;
            
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[sender locationInView:self.collectionView]];
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
                ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            CGRect cellFrame = cell.frame;
            cellFrame.origin.x += self.collectionView.frame.origin.x - self.collectionView.contentOffset.x;
            cellFrame.origin.y += 40 + (parentViewIndexPath.section * (parentCell.frame.size.height + 40));
            
            self.currentView = [[UIView alloc] initWithFrame:cellFrame];
            [cell setHighlighted:YES];
            
            UIView *highlightedImageView = [cell LX_snapshotView];
            [highlightedImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [highlightedImageView setAlpha:1.0f];
            
            [cell setHighlighted:NO];
            UIView *imageView = [cell LX_snapshotView];
            [imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [imageView setAlpha:0.0f];
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [_parentView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.currentView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    [highlightedImageView setAlpha:0.0f];
                    [cell.contentView setAlpha:0.0];
                    [imageView setAlpha:1.0f];
                }
            } completion:^(BOOL finished) {
                __strong typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [highlightedImageView removeFromSuperview];
                    if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                        [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                    }
                }
            }];
            [self invalidateLayout];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            CGPoint locationInCurrentCollectionView = [sender locationInView:currentCollectionView];
            NSIndexPath *collectionViewIndexPath = [currentCollectionView indexPathForItemAtPoint:locationInCurrentCollectionView];
            
            if ((((collectionViewIndexPath.section == self.selectedItemIndexPath.section) && (collectionViewIndexPath.item == self.selectedItemIndexPath.item)) && _sourceCollectionViewTag == currentCollectionView.tag) || locationInCurrentCollectionView.x < 0 || locationInCurrentCollectionView.y - 40 < 0) {
                [self returnCellToStartPosition];
            }else {
                NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
                
                DragndropCollectionViewCell *targetCell = (DragndropCollectionViewCell *)[currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndexPath.item inSection:collectionViewIndexPath.section]];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose action:" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self returnCellToStartPosition];
                }];
                [alert addAction:cancelAction];
                
                UIAlertAction *replaceAction = [UIAlertAction actionWithTitle:@"Replace" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self invalidateLayoutIfNecessary:YES withNewIndexPath:collectionViewIndexPath];
                    
                    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:currentIndexPath];
                    
                    if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                        [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                    }
                    
                    CGRect cellFrame = targetCell.frame;
                    cellFrame.origin.x += self.collectionView.frame.origin.x - self.collectionView.contentOffset.x;
                    cellFrame.origin.y += 40 + (parentViewIndexPath.section * (parentCell.frame.size.height + 40));
                    
                    UIView *targetView = [[UIView alloc] initWithFrame:cellFrame];
                    [targetCell setHighlighted:YES];
                    
                    CGPoint targetViewCenter = targetView.center;
                    
                    UIView *highlightedImageView = [targetCell LX_snapshotView];
                    [highlightedImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
                    [highlightedImageView setAlpha:0.5f];
                    
                    [targetView addSubview:highlightedImageView];
                    [_parentView addSubview:targetView];
                    
                    [targetCell.contentView setAlpha:0.0];
                    
                    [self.longPressGestureRecognizer setEnabled:NO];
                    __weak typeof(self) weakSelf = self;
                    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            [strongSelf.currentView setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                            [targetView setCenter:self.currentViewCenter];
                            [strongSelf.currentView setCenter:targetViewCenter];
                        }
                    } completion:^(BOOL finished) {
                        [self.longPressGestureRecognizer setEnabled:YES];
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            [cell.contentView setAlpha:1.0];
                            [targetCell.contentView setAlpha:1.0];
                            
                            self.selectedItemIndexPath = nil;
                            self.currentViewCenter = CGPointZero;
                            [strongSelf.currentView removeFromSuperview];
                            strongSelf.currentView = nil;
                            [targetView removeFromSuperview];
                            [strongSelf invalidateLayout];
                            
                            if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                            }
                        }
                    }];
                }];
                UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
                    
                    [self invalidateLayoutIfNecessary:NO withNewIndexPath:[NSIndexPath indexPathForItem:currentIndexPath.item inSection:collectionViewIndexPath.section]];
                    
                    if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                        [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                    }
                    
                    UICollectionViewCell *targetCell = [currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndexPath.item inSection:collectionViewIndexPath.section]];
                    
                    CGRect cellFrame = targetCell.frame;
                    cellFrame.origin.x += self.collectionView.frame.origin.x - self.collectionView.contentOffset.x;
                    cellFrame.origin.y += 40 + (parentViewIndexPath.section * (parentCell.frame.size.height + 40));
                    
                    UIView *targetView = [[UIView alloc] initWithFrame:cellFrame];
                    CGPoint targetViewCenter = targetView.center;
                    
                    __weak typeof(self) weakSelf = self;
                    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            [targetCell.contentView setAlpha:0.0];
                            [strongSelf.currentView setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                            [strongSelf.currentView setCenter:targetViewCenter];
                        }
                    } completion:^(BOOL finished) {
                        [self.longPressGestureRecognizer setEnabled:YES];
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            
                            self.selectedItemIndexPath = nil;
                            self.currentViewCenter = CGPointZero;
                            [strongSelf.currentView removeFromSuperview];
                            strongSelf.currentView = nil;
                            [targetView removeFromSuperview];
                            [strongSelf invalidateLayout];
                            
                            if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                            }
                        }
                    }];
                }];
                if (targetCell.currentType == empty) {
                    [alert addAction:replaceAction];
                    [alert addAction:addAction];
                    UIWindow *keyWindow = [[UIApplication sharedApplication]keyWindow];
                    UIViewController *mainController = [keyWindow rootViewController];
                    
                    [mainController presentViewController:alert animated:YES completion:nil];
                }else {
                    NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
                    
                    [self invalidateLayoutIfNecessary:NO withNewIndexPath:[NSIndexPath indexPathForItem:currentIndexPath.item inSection:collectionViewIndexPath.section]];
                    
                    if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                        [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                    }
                    
                    UICollectionViewCell *targetCell = [currentCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndexPath.item inSection:collectionViewIndexPath.section]];
                    
                    CGRect cellFrame = targetCell.frame;
                    cellFrame.origin.x += self.collectionView.frame.origin.x - self.collectionView.contentOffset.x;
                    cellFrame.origin.y += 40 + (parentViewIndexPath.section * (parentCell.frame.size.height + 40));
                    
                    UIView *targetView = [[UIView alloc] initWithFrame:cellFrame];
                    CGPoint targetViewCenter = targetView.center;
                    
                    __weak typeof(self) weakSelf = self;
                    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            [targetCell.contentView setAlpha:0.0];
                            [strongSelf.currentView setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
                            [strongSelf.currentView setCenter:targetViewCenter];
                        }
                    } completion:^(BOOL finished) {
                        [self.longPressGestureRecognizer setEnabled:YES];
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            self.selectedItemIndexPath = nil;
                            self.currentViewCenter = CGPointZero;
                            [strongSelf.currentView removeFromSuperview];
                            strongSelf.currentView = nil;
                            [targetView removeFromSuperview];
                            [strongSelf invalidateLayout];
                            
                            if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                                [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                            }
                        }
                    }];
                }
            }
            
            break;
        }
        default:
            break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            self.panTranslationInCollectionView = [sender translationInView:_parentView];
            CGPoint viewCenter = self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            if (viewCenter.y < (CGRectGetMinY(_parentView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                [self setupScrollTimerInDirection:LXScrollingDirectionUp];
            }else {
                if (viewCenter.y > (CGRectGetMaxY(_parentView.bounds) - self.scrollingTriggerEdgeInsets.top)) {
                    [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                }else {
                    [self invalidatesScrollTimer];
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            [self invalidatesScrollTimer];
            break;
        }
            
        default:
            break;
    }
}

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink {
    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown || direction == LXScrollingDirectionLeft || direction == LXScrollingDirectionRight) {
        return;
    }
    
    CGSize frameSize = _parentView.bounds.size;
    CGSize contentSize = _parentView.contentSize;
    CGPoint contentOffset = _parentView.contentOffset;
    UIEdgeInsets contentInset = _parentView.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f - contentInset.left;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    
    _parentView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}

#pragma mark - Actions
- (void)returnCellToStartPosition {
    NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:currentIndexPath];
    
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
        [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
    }
    
    [self.longPressGestureRecognizer setEnabled:NO];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.currentView setTransform:CGAffineTransformMakeScale(1.0f, 1.0f)];
            [strongSelf.currentView setCenter:self.currentViewCenter];
        }
    } completion:^(BOOL finished) {
        [self.longPressGestureRecognizer setEnabled:YES];
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [cell.contentView setAlpha:1.0];
            
            self.selectedItemIndexPath = nil;
            self.currentViewCenter = CGPointZero;
            [strongSelf.currentView removeFromSuperview];
            strongSelf.currentView = nil;
            [strongSelf invalidateLayout];
            
            if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
            }
        }
    }];
}

#pragma mark - Private

- (CGRect)frameForTrainingPlanAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat originX = indexPath.item * _itemSize.width;
    
    CGFloat originY = indexPath.section * _itemSize.height;
    
    return CGRectMake(originX, originY, _itemSize.width, _itemSize.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *allAttributes = [NSMutableArray arrayWithCapacity:self.layoutInfo.count];
    [self.layoutInfo enumerateKeysAndObjectsUsingBlock:^(NSString *elementIdentifier,
                                                         NSDictionary *elementsInfo,
                                                         BOOL *stop) {
        [elementsInfo enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath,
                                                          UICollectionViewLayoutAttributes *attributes,
                                                          BOOL *innerStop) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [allAttributes addObject:attributes];
            }
        }];
    }];
    
    return allAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.layoutInfo[dragndropLayoutCellKind][indexPath];
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(_numberOfColumns * _itemSize.width, self.collectionView.bounds.size.height);
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (self.currentView) {
        if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
            return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
        }
        
        if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
            return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
        }
    }
    
    return YES;
}

@end
