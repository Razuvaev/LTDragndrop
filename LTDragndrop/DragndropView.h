//
//  DragndropView.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragndropCollectionViewLayout.h"

@interface DragndropView : UIView <DragndropCollectionViewDataSource, DragndropCollectionViewLayout, UIGestureRecognizerDelegate>

/**
CollectionView for dragndrop cards
*/
@property (nonatomic, strong) UICollectionView *CV;

/**
Number of columns (items in one section)
*/
@property (nonatomic) NSInteger numberOfItemsInSection;

@end
