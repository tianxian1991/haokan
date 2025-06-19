//
//  ProfileViewController.m
//  Douyin
//
//  Created on 2024.
//

#import "ProfileViewController.h"
#import "SlideTabBar.h"
#import "EmptyStateView.h"

@interface ProfileViewController () <OnTabTapActionDelegate>

@property (nonatomic, strong) SlideTabBar *slideTabBar;
@property (nonatomic, strong) EmptyStateView *emptyStateView;
@property (nonatomic, strong) UIView *contentContainerView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNavigationBarTitle:@"我的"];
}

- (void)setupUI {
    // 设置顶部选项卡
    _slideTabBar = [[SlideTabBar alloc] init];
    _slideTabBar.delegate = self;
    [self.view addSubview:_slideTabBar];
    [_slideTabBar setLabels:@[@"我的在追", @"浏览记录"] tabIndex:0];
    
    // 设置布局
    _slideTabBar.frame = CGRectMake(0, StatusBarHeight + 44, ScreenWidth, 40);
    
    // 创建内容容器视图
    _contentContainerView = [[UIView alloc] init];
    _contentContainerView.frame = CGRectMake(0, 
                                      CGRectGetMaxY(_slideTabBar.frame), 
                                      ScreenWidth, 
                                      ScreenHeight - CGRectGetMaxY(_slideTabBar.frame));
    [self.view addSubview:_contentContainerView];
    
    // 创建空状态视图
    UIImage *emptyImage = [UIImage imageNamed:@"EmptyState"];
    
    _emptyStateView = [[EmptyStateView alloc] initWithFrame:_contentContainerView.bounds
                                                     image:emptyImage 
                                                   message:@"暂无内容，去剧场挑几部吧 ~" 
                                               buttonTitle:@"去剧场"];
    [_emptyStateView.actionButton addTarget:self action:@selector(goToTheater) forControlEvents:UIControlEventTouchUpInside];
    [_contentContainerView addSubview:_emptyStateView];
}

- (void)goToTheater {
    // 切换到tabbar的剧场标签页
    self.tabBarController.selectedIndex = 1;
}

#pragma mark - OnTabTapActionDelegate

- (void)onTabTapAction:(NSInteger)index {
    // 处理tab切换
    NSLog(@"Selected tab: %ld", (long)index);
    
    // 这里可以根据不同的选项卡展示不同的内容
    // 目前所有选项卡都显示空状态
}

@end 