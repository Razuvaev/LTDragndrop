//
//  DragndropCollectionViewCell.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
Cell type. E.g: workday or holiday
*/
typedef enum {
    empty = 0,
    white
}cellType;

@interface DragndropCollectionViewCell : UICollectionViewCell

/**
Setter for cell
*/
- (void)setupCellWithType:(cellType)cellType;

/**
Current type of cell
*/
@property (nonatomic) cellType currentType;

@end
