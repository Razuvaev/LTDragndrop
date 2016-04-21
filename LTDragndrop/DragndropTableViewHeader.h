//
//  DragndropTableViewHeader.h
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DragndropTableViewHeaderDelegate;

@interface DragndropTableViewHeader : UIView

@property (nonatomic) NSInteger currentSection;

- (void)setHeaderLabelWithSection:(NSInteger)section;

@property (nonatomic, weak) NSObject<DragndropTableViewHeaderDelegate> *delegate;

@end

@protocol DragndropTableViewHeaderDelegate <NSObject>
@optional

- (void)sectionTapped:(NSInteger)section;

@end