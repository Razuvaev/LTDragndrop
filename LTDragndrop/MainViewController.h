//
//  MainViewController.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DragndropTableViewHeader.h"

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, DragndropTableViewHeaderDelegate>

/**
Number of sections in initial TableView
*/
@property (nonatomic) NSInteger numberOfSections;

/**
Number of rows in section
*/
@property (nonatomic) NSInteger numberOfRowsInSection;

/**
Number of columns in dragndropView
*/
@property (nonatomic) NSInteger numberOfColumnsInDragndrop;

@end

