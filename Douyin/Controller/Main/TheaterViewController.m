//
//  TheaterViewController.m
//  Douyin
//
//  Created on 2024.
//

#import "TheaterViewController.h"
#import "SlideTabBar.h"
#import "EmptyStateView.h"

@interface TheaterViewController () <OnTabTapActionDelegate>

@property (nonatomic, strong) SlideTabBar *slideTabBar;
@property (nonatomic, strong) EmptyStateView *emptyStateView;
@property (nonatomic, strong) UIView *contentContainerView;

@end

@implementation TheaterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarTitle:@"剧场"];
}

- (void)setupUI {
    // 设置顶部选项卡
    _slideTabBar = [[SlideTabBar alloc] init];
    _slideTabBar.delegate = self;
    [self.view addSubview:_slideTabBar];
    [_slideTabBar setLabels:@[@"推荐", @"电视剧", @"电影", @"综艺"] tabIndex:0];
    
    // 设置布局
    _slideTabBar.frame = CGRectMake(0, StatusBarHeight + 44, ScreenWidth, 40);
    
    // 创建内容容器视图
    _contentContainerView = [[UIView alloc] init];
    _contentContainerView.frame = CGRectMake(0, 
                                      CGRectGetMaxY(_slideTabBar.frame), 
                                      ScreenWidth, 
                                      ScreenHeight - CGRectGetMaxY(_slideTabBar.frame));
    [self.view addSubview:_contentContainerView];
    
    // 创建空状态视图 - 实际应用中这里会显示电影/电视剧列表
    UIImage *emptyImage = [UIImage imageNamed:@"EmptyState"];
    
    _emptyStateView = [[EmptyStateView alloc] initWithFrame:_contentContainerView.bounds
                                                     image:emptyImage 
                                                   message:@"正在获取影片数据，请稍候..." 
                                               buttonTitle:@"刷新"];
    [_emptyStateView.actionButton addTarget:self action:@selector(refreshContent) forControlEvents:UIControlEventTouchUpInside];
    [_contentContainerView addSubview:_emptyStateView];
}

- (void)refreshContent {
    // 刷新内容
    NSLog(@"刷新内容");
}

#pragma mark - OnTabTapActionDelegate

- (void)onTabTapAction:(NSInteger)index {
    // 处理tab切换
    NSLog(@"Selected tab: %ld", (long)index);
    
    // 这里可以根据不同的选项卡展示不同的内容
    NSString *message = @"正在获取影片数据，请稍候...";
    switch (index) {
        case 0:
            message = @"正在获取推荐影片，请稍候...";
            break;
        case 1:
            message = @"正在获取电视剧数据，请稍候...";
            break;
        case 2:
            message = @"正在获取电影数据，请稍候...";
            break;
        case 3:
            message = @"正在获取综艺节目，请稍候...";
            break;
    }
    
    _emptyStateView.messageLabel.text = message;
}

@end 