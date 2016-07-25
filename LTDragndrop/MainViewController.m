//
//  MainViewController.m
//  LTDragndrop
//
//  Created by Pavel Razuvaev on 20/04/16.
//  Copyright © 2016 Pavel Razuvaev. All rights reserved.
//

#import "MainViewController.h"

#import "DragndropTableViewCell.h"
//#import "TrainingPlanFooterTableViewCell.h"

static NSString * const cellIdentifier = @"cellIdentifier";

static const CGFloat headerHeight = 40;
static const CGFloat oneRowHeight = 120;

@interface MainViewController ()

@property (nonatomic, strong) DragndropTableViewHeader *header;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MainViewController

#pragma mark - LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _numberOfSections = 3;
    _numberOfColumnsInDragndrop = 5;
    
    [self setupNavBar];
    [self setupUI];
}

#pragma mark - SetupUI
- (void)setupNavBar {
    self.title = @"Drag'n'drop";
}

- (void)setupUI {
    [self.view addSubview:self.tableView];
}

- (DragndropTableViewHeader *)header {
    _header = [[DragndropTableViewHeader alloc] init];
    [_header setDelegate:self];
    return _header;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView setDelegate:self];
        [_tableView setDataSource:self];
        [_tableView registerClass:[DragndropTableViewCell class] forCellReuseIdentifier:cellIdentifier];
        [_tableView setShowsVerticalScrollIndicator:NO];
        [_tableView setBackgroundColor:[UIColor whiteColor]];
        [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    return _tableView;
}

#pragma mark - TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return oneRowHeight*7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    DragndropTableViewHeader *header = self.header;
    [header setHeaderLabelWithSection:section];
    [header setCurrentSection:section];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DragndropTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[DragndropTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    [cell setNumberOfItemsInSection:_numberOfColumnsInDragndrop];
//    [cell.trainingPlan setDelegate:self];
//    [cell setEditable:YES];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

#pragma mark - TableViewHeaderDelegate
- (void)sectionTapped:(NSInteger)section {
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_tableView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [_header setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, headerHeight)];    
}

#pragma mark - Others
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
