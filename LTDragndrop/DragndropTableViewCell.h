//
//  DragndropTableViewCell.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragndropView.h"

@interface DragndropTableViewCell : UITableViewCell

@property (nonatomic) NSInteger numberOfItemsInSection;
@property (nonatomic, strong) DragndropView *dragndropView;

@end
