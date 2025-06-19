//
//  MainTabBarController.m
//  Douyin
//
//  Created on 2024.
//

#import "MainTabBarController.h"
#import "UserHomePageController.h"
#import "BaseViewController.h"
#import "TheaterViewController.h"
#import "SeriesViewController.h"
#import "ProfileViewController.h"
#import "HomeViewController.h"
#import "TabBarIconGenerator.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewControllers];
}

- (void)setupViewControllers {
    // 创建各个TabBar对应的控制器
    UIViewController *homeVC = [self createHomeViewController];
    UIViewController *theaterVC = [self createTheaterViewController];
    UIViewController *seriesVC = [self createSeriesViewController];
    UIViewController *profileVC = [self createProfileViewController];
    
    // 设置TabBar项
    self.viewControllers = @[
        [self createNavWithRootVC:homeVC title:@"首页"],
        [self createNavWithRootVC:theaterVC title:@"剧场"],
        [self createNavWithRootVC:seriesVC title:@"追剧"],
        [self createNavWithRootVC:profileVC title:@"我的"]
    ];
    
    // 设置TabBar外观
    self.tabBar.barTintColor = ColorThemeBackground;
    self.tabBar.tintColor = ColorThemeYellow;
    
    // iOS 13之后的系统适配
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithDefaultBackground];
        appearance.backgroundColor = ColorThemeBackground;
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: ColorWhiteAlpha60};
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: ColorThemeYellow};
        self.tabBar.standardAppearance = appearance;
        
        if (@available(iOS 15.0, *)) {
            self.tabBar.scrollEdgeAppearance = appearance;
        }
    }
}

- (UINavigationController *)createNavWithRootVC:(UIViewController *)rootVC title:(NSString *)title {
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    rootVC.title = title;
    
    UIImage *normalImage = [TabBarIconGenerator generateIconWithName:title selected:NO];
    UIImage *selectedImage = [TabBarIconGenerator generateIconWithName:title selected:YES];
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:title 
                                                             image:normalImage 
                                                     selectedImage:selectedImage];
    
    nav.tabBarItem = tabBarItem;
    return nav;
}

#pragma mark - View Controllers

- (UIViewController *)createHomeViewController {
    // 使用新创建的HomeViewController作为首页
    HomeViewController *homeVC = [[HomeViewController alloc] init];
    return homeVC;
}

- (UIViewController *)createTheaterViewController {
    // 创建剧场页面
    TheaterViewController *theaterVC = [[TheaterViewController alloc] init];
    return theaterVC;
}

- (UIViewController *)createSeriesViewController {
    // 创建追剧页面
    SeriesViewController *seriesVC = [[SeriesViewController alloc] init];
    return seriesVC;
}

- (UIViewController *)createProfileViewController {
    // 创建个人页面
    ProfileViewController *profileVC = [[ProfileViewController alloc] init];
    return profileVC;
}

@end 