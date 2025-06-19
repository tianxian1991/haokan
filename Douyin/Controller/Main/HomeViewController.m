//
//  HomeViewController.m
//  Douyin
//
//  Created on 2024.
//

#import "HomeViewController.h"
#import "SlideTabBar.h"
#import "AwemeListController.h"
#import "Aweme.h"
#import "Video.h"
#import "User.h"
#import <objc/runtime.h>

#ifndef ScreenWidth
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#endif

#ifndef ScreenHeight
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#endif

#ifndef ColorThemeBackground
#define ColorThemeBackground [UIColor colorWithRed:14.0/255.0 green:15.0/255.0 blue:26.0/255.0 alpha:1.0]
#endif

#ifndef ColorWhiteAlpha60
#define ColorWhiteAlpha60 [UIColor colorWithWhite:1.0 alpha:0.6]
#endif

@interface HomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, OnTabTapActionDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSMutableArray *videoSections; // 剧单数据源
@property (nonatomic, strong) NSMutableArray *followingSections; // 在追数据源（新增）

// 顶部选项卡
@property (nonatomic, strong) SlideTabBar *slideTabBar;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, assign) NSInteger currentTabIndex; // 添加当前选中标签索引

// 内容视图
@property (nonatomic, strong) UIViewController *currentContentVC;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) AwemeListController *recommendVC;

@end

@implementation HomeViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadData];
    
    // 设置初始标签索引
    _currentTabIndex = 0;
    
    // 默认显示"在追"页面
    [self showFollowingContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 隐藏导航栏
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 离开页面时恢复导航栏，避免影响其他页面
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _collectionView.frame = self.contentContainerView.bounds;
}

#pragma mark - UI Setup

- (void)setupUI {
    // 设置背景颜色
    [self setBackgroundColor:ColorThemeBackground];
    
    // 创建顶部选项卡
    _slideTabBar = [[SlideTabBar alloc] init];
    _slideTabBar.delegate = self;
    [self.view addSubview:_slideTabBar];
    [_slideTabBar setLabels:@[@"在追", @"剧单", @"推荐"] tabIndex:0];
    
    // 修改SlideTabBar位置，使其居中显示
    CGFloat tabBarWidth = ScreenWidth * 0.6; // 设置为屏幕宽度的60%
    _slideTabBar.frame = CGRectMake((ScreenWidth - tabBarWidth) / 2, StatusBarHeight, tabBarWidth, 40);
    _slideTabBar.backgroundColor = [UIColor clearColor]; // 设置背景透明
    
    // 添加双击手势用于测试空状态和有数据状态切换
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [_slideTabBar addGestureRecognizer:doubleTapGesture];
    
    // 创建搜索按钮
    _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _searchButton.frame = CGRectMake(ScreenWidth - 50, StatusBarHeight, 50, 40);
    [_searchButton setImage:[self generateSearchIcon] forState:UIControlStateNormal];
    [_searchButton addTarget:self action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _searchButton.hidden = YES; // 初始隐藏搜索按钮
    [self.view addSubview:_searchButton];
    
    // 创建编辑按钮 - 更新样式与图片一致
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    editButton.frame = CGRectMake(ScreenWidth - 60, StatusBarHeight, 50, 40);
    [editButton setTitle:@"编辑" forState:UIControlStateNormal];
    [editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    editButton.titleLabel.font = [UIFont systemFontOfSize:14];
    editButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [editButton addTarget:self action:@selector(editButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    editButton.tag = 1002; // 设置标记以便于查找
    
    // 调整文字和图标的位置
    [editButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
    
    // 添加铅笔图标
    UIImageView *pencilIcon = [[UIImageView alloc] initWithFrame:CGRectMake(32, 13, 15, 15)];
    pencilIcon.image = [self generatePencilIcon];
    pencilIcon.contentMode = UIViewContentModeScaleAspectFit;
    [editButton addSubview:pencilIcon];
    
    editButton.hidden = YES; // 初始隐藏编辑按钮
    [self.view addSubview:editButton];
    
    // 创建内容容器视图
    _contentContainerView = [[UIView alloc] init];
    _contentContainerView.frame = CGRectMake(0, CGRectGetMaxY(_slideTabBar.frame), ScreenWidth, ScreenHeight - CGRectGetMaxY(_slideTabBar.frame) - SafeAreaBottomHeight);
    [self.view addSubview:_contentContainerView];
    
    // 创建布局
    _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _flowLayout.minimumLineSpacing = 20;
    _flowLayout.minimumInteritemSpacing = 10;
    _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 20, 10);
    
    // 创建集合视图
    _collectionView = [[UICollectionView alloc] initWithFrame:self.contentContainerView.bounds collectionViewLayout:_flowLayout];
    _collectionView.backgroundColor = ColorThemeBackground;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsVerticalScrollIndicator = NO;
    
    // 注册单元格和头部视图
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    
    [self.contentContainerView addSubview:_collectionView];
}

#pragma mark - Data Loading

- (void)loadData {
    // 加载"剧单"页面数据
    _videoSections = [NSMutableArray array];
    
    // 创建"剧单"示例数据
    NSMutableDictionary *section1 = [NSMutableDictionary dictionary];
    [section1 setValue:@"98%用户在追🔥男频进站必看" forKey:@"title"];
    [section1 setValue:@[
        @"出手", @"阳谋", @"飞龙在天", @"拨开云雾见天日", 
        @"林深不知云海", @"秋日恋曲", @"初见", @"世间再无颜如玉", 
        @"长风渡", @"暗夜行者", @"赤子之心", @"天涯共此时", 
        @"烟雨江湖", @"剑影长情", @"风云再起"
    ] forKey:@"videos"];
    
    [section1 setValue:@[
        @"全74集", @"全90集", @"全133集", @"全55集", 
        @"全72集", @"全81集", @"全95集", @"全103集", 
        @"全112集", @"全85集", @"全91集", @"全79集", 
        @"全108集", @"全75集", @"全88集"
    ] forKey:@"episodes"];
    
    NSMutableDictionary *section2 = [NSMutableDictionary dictionary];
    [section2 setValue:@"千万剧迷在追🔥女频进站必看" forKey:@"title"];
    [section2 setValue:@[
        @"爱意满乡间", @"私藏", @"危情博弈", @"我被迫营业了", 
        @"流金岁月", @"余生请多指教", @"春日宴", @"暗格里的秘密", 
        @"你是我的荣耀", @"星汉灿烂", @"梦华录", @"且试天下", 
        @"镜双城", @"玫瑰之战", @"良辰好景知几何"
    ] forKey:@"videos"];
    
    [section2 setValue:@[
        @"全64集", @"全70集", @"全69集", @"全80集", 
        @"全78集", @"全65集", @"全60集", @"全72集", 
        @"全32集", @"全40集", @"全40集", @"全38集", 
        @"全56集", @"全30集", @"全48集"
    ] forKey:@"episodes"];
    
    NSMutableDictionary *section3 = [NSMutableDictionary dictionary];
    [section3 setValue:@"6月第3周🔥热门新剧速递" forKey:@"title"];
    [section3 setValue:@[
        @"觉醒当天，我当上了全团状元", @"错嫁萌妻包养我", @"不朽", @"梅香棋韵", 
        @"陪你到世界终结", @"春日宴", @"长风渡", @"我的人间烟火", 
        @"夜月行", @"风起洛阳", @"与凤行", @"苍兰诀", 
        @"沉香如屑", @"且听凤鸣", @"尘缘"
    ] forKey:@"videos"];
    
    [section3 setValue:@[
        @"全88集", @"全89集", @"全55集", @"全120集", 
        @"全36集", @"全40集", @"全41集", @"全39集", 
        @"全42集", @"全45集", @"全48集", @"全52集", 
        @"全38集", @"全43集", @"全58集"
    ] forKey:@"episodes"];
    
    [_videoSections addObject:section1];
    [_videoSections addObject:section2];
    [_videoSections addObject:section3];
    
    // 加载"在追"页面数据 - 使用扁平结构，没有section
    _followingSections = [NSMutableArray array];
    
    // 创建"在追"视频数据 - 使用与截图一致的数据
    NSMutableArray *videos = [NSMutableArray arrayWithArray:@[@"不朽", @"爱意满乡间", @"出手", @"林深不知云海"]];
    NSMutableArray *episodes = [NSMutableArray arrayWithArray:@[@"全55集", @"全64集", @"全74集", @"全84集"]];
    NSMutableArray *progress = [NSMutableArray arrayWithArray:@[@"观看至1集", @"观看至2集", @"观看至1集", @"观看至1集"]];
    
    // 创建直接的数据结构
    NSMutableDictionary *followingData = [NSMutableDictionary dictionary];
    [followingData setValue:videos forKey:@"videos"];
    [followingData setValue:episodes forKey:@"episodes"];
    [followingData setValue:progress forKey:@"progress"];
    
    [_followingSections addObject:followingData];
    
    [_collectionView reloadData];
}

// 清空数据用于测试空状态
- (void)clearData {
    if (_currentTabIndex == 0) {
        _followingSections = [NSMutableArray array];
    } else {
        _videoSections = [NSMutableArray array];
    }
    
    [_collectionView reloadData];
    
    if (_currentTabIndex == 0) {
        [self showFollowingContent]; // 刷新在追页面显示空状态
    }
}

// 重新加载数据
- (void)reloadData {
    [self loadData];
    
    if (_currentTabIndex == 0) {
        [self showFollowingContent]; // 刷新在追页面显示数据状态
    }
}

#pragma mark - OnTabTapActionDelegate

- (void)onTabTapAction:(NSInteger)index {
    // 处理顶部选项卡切换
    NSLog(@"切换到选项卡: %ld", (long)index);
    
    // 更新当前标签索引
    _currentTabIndex = index;
    
    // 清除当前内容
    for (UIView *subview in self.contentContainerView.subviews) {
        [subview removeFromSuperview];
    }
    
    // 移除可能的section背景视图和滚动视图
    for (UIView *view in _collectionView.subviews) {
        if (view.tag >= 100 && view.tag < 300) {  // 包括背景(100-199)和滚动视图(200-299)
            [view removeFromSuperview];
        }
    }
    
    if (_currentContentVC) {
        [_currentContentVC removeFromParentViewController];
        _currentContentVC = nil;
    }
    
    // 显示/隐藏搜索按钮和编辑按钮
    _searchButton.hidden = (index != 1); // 仅在"剧单"标签显示搜索按钮
    
    // 获取编辑按钮
    UIButton *editButton = [self.view viewWithTag:1002];
    // 初始隐藏编辑按钮，在showFollowingContent中根据是否有数据决定是否显示
    editButton.hidden = YES;
    
    switch (index) {
        case 0: // 在追
            [self showFollowingContent];
            break;
        case 1: // 剧单
            [self showPlaylistContent];
            break;
        case 2: // 推荐
            [self showRecommendContent];
            break;
        default:
            break;
    }
}

#pragma mark - Content Display

- (void)showFollowingContent {
    // 显示在追内容（使用CollectionView）
    [self.contentContainerView addSubview:_collectionView];
    
    // 获取编辑按钮
    UIButton *editButton = [self.view viewWithTag:1002];
    
    // 检查是否有数据
    if (_followingSections.count == 0) {
        // 没有数据时显示空状态视图
        [self showEmptyStateViewForFollowing];
        // 隐藏编辑按钮
        editButton.hidden = YES;
    } else {
        // 有数据时移除空状态视图
        [self removeEmptyStateView];
        // 显示编辑按钮
        editButton.hidden = NO;
        
        // 修改布局样式为在追页面的样式，每行3个
        _flowLayout.minimumLineSpacing = 15;
        _flowLayout.minimumInteritemSpacing = 15;
        _flowLayout.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
        [_flowLayout invalidateLayout];
    }
    
    // 刷新数据显示
    [_collectionView reloadData];
}

- (void)showPlaylistContent {
    // 显示剧单内容（使用CollectionView）
    [self.contentContainerView addSubview:_collectionView];
    
    // 使用垂直滚动，但每个section内水平布局
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    _flowLayout.minimumLineSpacing = 20;  // section之间的垂直间距
    _flowLayout.minimumInteritemSpacing = 10;  // 同一section内的项目间距
    _flowLayout.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
    [_flowLayout invalidateLayout];
    
    // 刷新数据显示
    [_collectionView reloadData];
    
    // 在布局完成后添加section背景
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addHorizontalScrollableBackgrounds];
    });
}

- (void)addHorizontalScrollableBackgrounds {
    // 先移除旧的背景视图
    for (UIView *view in _collectionView.subviews) {
        if (view.tag >= 100 && view.tag < 300) {
            [view removeFromSuperview];
        }
    }
    
    // 移除已有的主滚动视图
    for (UIView *view in self.contentContainerView.subviews) {
        if (view.tag == 999) {
            [view removeFromSuperview];
        }
    }
    
    // 创建可滚动的主容器视图
    UIScrollView *mainScrollView = [[UIScrollView alloc] initWithFrame:_collectionView.bounds];
    mainScrollView.backgroundColor = [UIColor clearColor];
    mainScrollView.showsVerticalScrollIndicator = NO;
    mainScrollView.tag = 999; // 特殊标记
    [self.contentContainerView addSubview:mainScrollView];
    
    // 为每个section添加背景和水平滚动视图
    CGFloat totalHeight = 0;
    
    for (NSInteger section = 0; section < _videoSections.count; section++) {
        // 创建背景视图和滚动视图的位置计算
        CGFloat yOffset = 15 + section * 215; // 减小垂直间距，与图片一致
        
        // 创建section背景
        UIView *sectionBg = [[UIView alloc] initWithFrame:CGRectMake(15, yOffset, ScreenWidth - 30, 200)];
        sectionBg.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
        sectionBg.layer.cornerRadius = 10;
        sectionBg.tag = 100 + section;
        
        [mainScrollView addSubview:sectionBg];
        
        // 添加标题视图
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, sectionBg.bounds.size.width, 40)];
        
        // 使用图片中的三横线图标而不是自己绘制
        UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 20, 20)];
        iconImageView.backgroundColor = [UIColor clearColor];
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        iconImageView.image = [UIImage imageNamed:@"list_icon"] ?: [self generateListIcon];
        [headerView addSubview:iconImageView];
        
        // 标题
        NSString *title = _videoSections[section][@"title"];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(iconImageView.frame) + 10, 0, sectionBg.bounds.size.width - 100, 40)];
        titleLabel.text = title;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [headerView addSubview:titleLabel];
        
        // 更多按钮
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.frame = CGRectMake(sectionBg.bounds.size.width - 70, 0, 60, 40);
        [moreButton setTitle:@"更多>" forState:UIControlStateNormal];
        [moreButton setTitleColor:ColorWhiteAlpha60 forState:UIControlStateNormal];
        moreButton.titleLabel.font = [UIFont systemFontOfSize:14];
        moreButton.tag = section;
        [moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:moreButton];
        
        [sectionBg addSubview:headerView];
        
        // 创建水平滚动视图并放置在单元格区域
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, sectionBg.bounds.size.width, 160)];
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.backgroundColor = [UIColor clearColor];
        scrollView.tag = 200 + section; // 使用不同的tag范围标识滚动视图
        
        // 为滚动视图添加内容
        [self addItemsToScrollView:scrollView forSection:section];
        
        [sectionBg addSubview:scrollView];
        
        // 更新总高度
        totalHeight = CGRectGetMaxY(sectionBg.frame) + 15;
    }
    
    // 设置主滚动视图的内容大小
    mainScrollView.contentSize = CGSizeMake(ScreenWidth, totalHeight);
}

- (UIImage *)generateListIcon {
    // 生成图标 - 三条水平线
    CGSize iconSize = CGSizeMake(20, 20);
    UIGraphicsBeginImageContextWithOptions(iconSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextSetLineWidth(context, 1.0);
    
    // 绘制三条水平线
    CGContextAddRect(context, CGRectMake(0, 4, 20, 2));
    CGContextAddRect(context, CGRectMake(0, 10, 20, 2));
    CGContextAddRect(context, CGRectMake(0, 16, 20, 2));
    CGContextFillPath(context);
    
    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return iconImage;
}

- (void)addItemsToScrollView:(UIScrollView *)scrollView forSection:(NSInteger)section {
    // 获取section数据
    NSDictionary *sectionData = _videoSections[section];
    NSArray *videos = sectionData[@"videos"];
    NSArray *episodes = sectionData[@"episodes"];
    
    // 最多显示15个项目
    NSInteger itemCount = MIN(videos.count, 15);
    
    // 计算项目大小 - 根据图片调整比例，改为3.5个一行
    CGFloat paddingLeft = 12; // 左侧padding
    CGFloat paddingRight = 12; // 右侧padding
    CGFloat itemSpacing = 10; // 项目间距
    
    // 每个项目宽度 = (总宽度 - 左右边距 - 2个间距) / 3.5个
    CGFloat itemWidth = (scrollView.bounds.size.width - paddingLeft - paddingRight - itemSpacing * 2) / 3.2;
    CGFloat itemHeight = itemWidth * 1.45; // 与图片中比例一致
    
    // 设置滚动视图内容大小，确保能看到一点第4个项目
    scrollView.contentSize = CGSizeMake(paddingLeft + (itemWidth + itemSpacing) * itemCount, itemHeight);
    
    // 创建项目视图
    for (NSInteger i = 0; i < itemCount; i++) {
        // 创建单元格容器
        UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(paddingLeft + i * (itemWidth + itemSpacing), 5, itemWidth, itemHeight)];
        itemView.backgroundColor = [UIColor clearColor];
        itemView.clipsToBounds = YES;
        
        // 标题和集数
        NSString *videoTitle = videos[i];
        NSString *episodeCount = episodes[i];
        
        // 创建封面图片
        UIImageView *coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, itemWidth, itemHeight - 20)];
        coverImageView.backgroundColor = [UIColor darkGrayColor]; // 使用统一的深灰色背景
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        coverImageView.clipsToBounds = YES;
        coverImageView.layer.cornerRadius = 6.0; // 使圆角更小，与图片一致
        [itemView addSubview:coverImageView];
        
        // 集数标签 - 放在右下角，与图片一致
        UILabel *episodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, coverImageView.bounds.size.height - 20, itemWidth, 20)];
        episodeLabel.text = episodeCount;
        episodeLabel.textColor = [UIColor whiteColor];
        episodeLabel.font = [UIFont systemFontOfSize:12];
        episodeLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5]; // 添加半透明背景
        episodeLabel.textAlignment = NSTextAlignmentCenter;
        [coverImageView addSubview:episodeLabel];
        
        // 标题标签
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(coverImageView.frame), itemWidth, 20)];
        titleLabel.text = videoTitle;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:13]; // 更小的字体
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.numberOfLines = 1;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumScaleFactor = 0.7;
        [itemView addSubview:titleLabel];
        
        // 如果是第三个section的项目，添加"新剧"标签
        if (section == 2) {
            UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, 30, 16)];
            newLabel.text = @"新剧";
            newLabel.textColor = [UIColor whiteColor];
            newLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
            newLabel.font = [UIFont boldSystemFontOfSize:10];
            newLabel.textAlignment = NSTextAlignmentCenter;
            newLabel.layer.cornerRadius = 2;
            newLabel.layer.masksToBounds = YES;
            [coverImageView addSubview:newLabel];
        }
        
        // 添加点击事件
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(itemTapped:)];
        itemView.tag = i;
        itemView.userInteractionEnabled = YES;
        [itemView addGestureRecognizer:tapGesture];
        
        [scrollView addSubview:itemView];
    }
}

// 项目点击事件处理
- (void)itemTapped:(UITapGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    UIScrollView *scrollView = (UIScrollView *)view.superview;
    NSInteger section = scrollView.tag - 200;
    NSInteger item = view.tag;
    
    // 处理点击事件
    NSDictionary *sectionData = _videoSections[section];
    NSArray *videos = sectionData[@"videos"];
    NSString *videoTitle = videos[item];
    
    NSLog(@"选择了视频: %@", videoTitle);
}

- (void)showRecommendContent {
    // 显示推荐内容（使用AwemeListController）
    if (!_recommendVC) {
        // 创建一个简单的Aweme对象作为初始数据
        Aweme *dummyAweme = [[Aweme alloc] init];
        dummyAweme.desc = @"加载中...";
        dummyAweme.aweme_id = @"dummy_id";
        
        // 创建视频对象
        Video *video = [[Video alloc] init];
        
        // 创建播放地址对象
        id playAddr = [[NSClassFromString(@"Play_addr") alloc] init];
        // 设置一个有效的URL数组
        [playAddr setValue:@"play_addr_uri" forKey:@"uri"];
        [playAddr setValue:@[@"https://example.com/video.mp4"] forKey:@"url_list"];
        video.play_addr = playAddr;
        
        // 创建低质量播放地址对象
        id playAddrLowbr = [[NSClassFromString(@"Play_addr_lowbr") alloc] init];
        [playAddrLowbr setValue:@"play_addr_lowbr_uri" forKey:@"uri"];
        [playAddrLowbr setValue:@[@"https://example.com/video_low.mp4"] forKey:@"url_list"];
        video.play_addr_lowbr = playAddrLowbr;
        
        // 创建封面对象
        id cover = [[NSClassFromString(@"Cover") alloc] init];
        [cover setValue:@"cover_uri" forKey:@"uri"];
        [cover setValue:@[@"https://example.com/cover.jpg"] forKey:@"url_list"];
        video.cover = cover;
        
        // 设置其他必要的视频属性
        video.width = 720;
        video.height = 1280;
        video.duration = 15000;
        dummyAweme.video = video;
        
        // 创建用户对象
        User *author = [[User alloc] init];
        author.nickname = @"抖音用户";
        author.uid = @"dummy_user_id";
        
        // 创建头像对象
        id avatar = [[NSClassFromString(@"Avatar") alloc] init];
        [avatar setValue:@"avatar_uri" forKey:@"uri"];
        [avatar setValue:@[@"https://example.com/avatar.jpg"] forKey:@"url_list"];
        
        // 设置不同尺寸的头像
        [author setValue:avatar forKey:@"avatar_thumb"];
        [author setValue:avatar forKey:@"avatar_medium"];
        [author setValue:avatar forKey:@"avatar_larger"];
        
        dummyAweme.author = author;
        
        // 创建统计信息
        id statistics = [[NSClassFromString(@"Statistics") alloc] init];
        [statistics setValue:@100 forKey:@"comment_count"];
        [statistics setValue:@500 forKey:@"digg_count"];
        [statistics setValue:@50 forKey:@"share_count"];
        [statistics setValue:dummyAweme.aweme_id forKey:@"aweme_id"];
        dummyAweme.statistics = statistics;
        
        // 创建分享信息
        id shareInfo = [[NSClassFromString(@"Aweme_share_info") alloc] init];
        [shareInfo setValue:@"分享视频" forKey:@"share_title"];
        [shareInfo setValue:@"https://example.com/share" forKey:@"share_url"];
        [shareInfo setValue:@"精彩视频" forKey:@"share_desc"];
        dummyAweme.share_info = shareInfo;
        
        // 创建一个数组，包含一个简单的Aweme对象
        NSMutableArray<Aweme *> *dummyData = [NSMutableArray arrayWithObject:dummyAweme];
        
        // 创建AwemeListController实例，传入初始数据
        _recommendVC = [[AwemeListController alloc] initWithVideoData:dummyData
                                                         currentIndex:0 
                                                            pageIndex:1 
                                                             pageSize:10 
                                                            awemeType:AwemeWork 
                                                                  uid:nil];
        
        // 隐藏导航栏及返回按钮
        [_recommendVC initNavigationBarTransparent];
        
        // 获取子视图并隐藏返回按钮
        [_recommendVC.navigationItem setHidesBackButton:YES animated:NO];
        
        // 清空左侧按钮
        _recommendVC.navigationItem.leftBarButtonItem = nil;
        
        // 不调用setLeftButton方法，这样就不会显示返回按钮
        Method originalMethod = class_getInstanceMethod([_recommendVC class], @selector(setLeftButton:));
        if (originalMethod) {
            Method replacementMethod = class_getInstanceMethod([self class], @selector(emptyMethod));
            method_exchangeImplementations(originalMethod, replacementMethod);
        }
    }
    
    [self addChildViewController:_recommendVC];
    [self.contentContainerView addSubview:_recommendVC.view];
    _recommendVC.view.frame = self.contentContainerView.bounds;
    [_recommendVC didMoveToParentViewController:self];
    _currentContentVC = _recommendVC;
}

// 空方法，用于替换setLeftButton方法
- (void)emptyMethod:(NSString *)imageName {
    // 空实现，什么都不做
}

// 添加空状态视图
- (void)showEmptyStateViewForFollowing {
    // 移除已有的空状态视图
    [self removeEmptyStateView];
    
    // 创建空状态容器
    UIView *emptyStateView = [[UIView alloc] initWithFrame:self.contentContainerView.bounds];
    emptyStateView.tag = 1001; // 设置标记以便于后续查找
    emptyStateView.backgroundColor = ColorThemeBackground;
    
    // 创建空椅子图片
    UIImageView *chairImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    chairImageView.center = CGPointMake(emptyStateView.center.x, emptyStateView.center.y - 50);
    chairImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // 绘制椅子图形
    CGSize imageSize = CGSizeMake(150, 150);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 设置颜色为灰色
    [[UIColor darkGrayColor] setFill];
    [[UIColor darkGrayColor] setStroke];
    
    // 椅子座位
    CGContextAddRect(context, CGRectMake(30, 50, 90, 40));
    CGContextFillPath(context);
    
    // 椅子靠背
    CGContextAddRect(context, CGRectMake(30, 20, 90, 30));
    CGContextFillPath(context);
    
    // 椅子左腿
    CGContextAddRect(context, CGRectMake(30, 90, 15, 40));
    CGContextFillPath(context);
    
    // 椅子右腿
    CGContextAddRect(context, CGRectMake(105, 90, 15, 40));
    CGContextFillPath(context);
    
    // 椅子右扶手
    CGContextAddRect(context, CGRectMake(120, 50, 20, 60));
    CGContextFillPath(context);
    
    // 椅子左扶手
    CGContextAddRect(context, CGRectMake(10, 50, 20, 60));
    CGContextFillPath(context);
    
    // 添加小红点
    [[UIColor redColor] setFill];
    CGContextAddEllipseInRect(context, CGRectMake(30, 15, 10, 10));
    CGContextFillPath(context);
    
    UIImage *chairImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    chairImageView.image = chairImage;
    [emptyStateView addSubview:chairImageView];
    
    // 创建提示文本
    UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(chairImageView.frame) + 20, emptyStateView.bounds.size.width, 30)];
    emptyLabel.text = @"暂无内容，去剧场挑几部吧～";
    emptyLabel.textColor = [UIColor lightGrayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.font = [UIFont systemFontOfSize:16];
    [emptyStateView addSubview:emptyLabel];
    
    // 创建"去剧场"按钮
    UIButton *goToTheaterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    goToTheaterButton.frame = CGRectMake((emptyStateView.bounds.size.width - 150) / 2, CGRectGetMaxY(emptyLabel.frame) + 30, 150, 45);
    goToTheaterButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    [goToTheaterButton setTitle:@"去剧场" forState:UIControlStateNormal];
    [goToTheaterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    goToTheaterButton.titleLabel.font = [UIFont systemFontOfSize:16];
    goToTheaterButton.layer.cornerRadius = 22.5;
    goToTheaterButton.layer.masksToBounds = YES;
    [goToTheaterButton addTarget:self action:@selector(goToTheaterButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [emptyStateView addSubview:goToTheaterButton];
    
    [self.contentContainerView addSubview:emptyStateView];
}

// 移除空状态视图
- (void)removeEmptyStateView {
    for (UIView *subview in self.contentContainerView.subviews) {
        if (subview.tag == 1001) {
            [subview removeFromSuperview];
            break;
        }
    }
}

// 去剧场按钮点击事件
- (void)goToTheaterButtonTapped:(UIButton *)sender {
    NSLog(@"去剧场按钮被点击");
    // 这里可以添加跳转到剧场页面的逻辑
    // 例如：跳转到第二个标签页（剧单页面）
    [self onTabTapAction:1];
}

// 处理双击手势
- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:_slideTabBar];
    
    // 根据点击位置确定是哪个标签
    CGFloat tabWidth = _slideTabBar.frame.size.width / 3;
    NSInteger tabIndex = location.x / tabWidth;
    
    if (tabIndex == 0) { // 双击"在追"标签
        // 切换数据状态
        static BOOL hasData = YES;
        
        if (hasData) {
            [self clearData];
        } else {
            [self reloadData];
        }
        
        hasData = !hasData;
        NSLog(@"双击在追标签，切换数据状态: %@", hasData ? @"有数据" : @"无数据");
        
        // 获取编辑按钮并根据数据状态更新显示
        UIButton *editButton = [self.view viewWithTag:1002];
        editButton.hidden = !hasData; // 有数据时显示，无数据时隐藏
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    // 根据当前选中的标签返回对应的段数
    if (_currentTabIndex == 0) {
        return 1; // 在追页面只有一个section
    } else if (_currentTabIndex == 1) {
        return 0; // 不使用CollectionView的section，改为自定义布局
    } else {
        return 0;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // 根据当前选中的标签返回对应的单元格数
    if (_currentTabIndex == 0) {
        if (_followingSections.count > 0) {
            NSDictionary *followingData = _followingSections[0];
            NSArray *videos = followingData[@"videos"];
            return videos.count;
        }
        return 0;
    } else if (_currentTabIndex == 1) {
        return 0; // 剧单页面不使用collectionView项目，使用自定义滚动视图
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
    
    // 清除旧视图
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    // 配置单元格UI
    cell.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    cell.layer.cornerRadius = 8.0;
    cell.layer.masksToBounds = YES;
    
    // 获取视频数据 - 根据当前标签选择不同的数据源
    NSString *videoTitle;
    NSString *episodeCount;
    
    if (_currentTabIndex == 0) {
        // 在追页面数据 - 使用扁平结构
        NSDictionary *followingData = _followingSections[0];
        NSArray *videos = followingData[@"videos"];
        NSArray *episodes = followingData[@"episodes"];
        videoTitle = videos[indexPath.item];
        episodeCount = episodes[indexPath.item];
    } else {
        // 剧单页面数据
        NSDictionary *sectionData = _videoSections[indexPath.section];
        NSArray *videos = sectionData[@"videos"];
        NSArray *episodes = sectionData[@"episodes"];
        videoTitle = videos[indexPath.item];
        episodeCount = episodes[indexPath.item];
    }
    
    // 创建封面图片
    UIImageView *coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height - (_currentTabIndex == 0 ? 45 : 30))];
    coverImageView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    coverImageView.clipsToBounds = YES;
    [cell.contentView addSubview:coverImageView];
    
    // 集数标签
    UILabel *episodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, coverImageView.bounds.size.height - 25, 100, 20)];
    episodeLabel.text = episodeCount;
    episodeLabel.textColor = [UIColor whiteColor];
    episodeLabel.font = [UIFont systemFontOfSize:12];
    [coverImageView addSubview:episodeLabel];
    
    // 标题标签 - 调整字体大小以适应更小的宽度
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(coverImageView.frame) + 5, cell.bounds.size.width - 20, _currentTabIndex == 0 ? 20 : 25)];
    titleLabel.text = videoTitle;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:_currentTabIndex == 0 ? 14 : 14];
    titleLabel.textAlignment = _currentTabIndex == 0 ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    [cell.contentView addSubview:titleLabel];
    
    // 为在追页面添加观看至几集标签 - 使用真实的进度数据
    if (_currentTabIndex == 0) {
        UILabel *watchingProgressLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(titleLabel.frame) + 2, cell.bounds.size.width - 20, 20)];
        NSDictionary *followingData = _followingSections[0];
        NSArray *progressArray = followingData[@"progress"];
        if (progressArray && indexPath.item < progressArray.count) {
            watchingProgressLabel.text = progressArray[indexPath.item];
        }
        watchingProgressLabel.textColor = [UIColor lightGrayColor];
        watchingProgressLabel.font = [UIFont systemFontOfSize:12];
        watchingProgressLabel.textAlignment = NSTextAlignmentLeft;
        [cell.contentView addSubview:watchingProgressLabel];
    }
    
    // 如果是新剧，添加标签
    if ((indexPath.section == 2 && _currentTabIndex == 1) || 
        (indexPath.item == 0 && _currentTabIndex == 0)) {
        UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 35, 20)];
        newLabel.text = @"新剧";
        newLabel.textColor = [UIColor whiteColor];
        newLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0];
        newLabel.font = [UIFont boldSystemFontOfSize:12];
        newLabel.textAlignment = NSTextAlignmentCenter;
        newLabel.layer.cornerRadius = 4;
        newLabel.layer.masksToBounds = YES;
        [coverImageView addSubview:newLabel];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];
        
        // 清除旧视图
        for (UIView *view in header.subviews) {
            [view removeFromSuperview];
        }
        
        // 在追页面不显示标题头
        if (_currentTabIndex == 0) {
            return header;
        }
        
        // 获取剧单页面数据
        NSDictionary *sectionData = _videoSections[indexPath.section];
        NSString *title = sectionData[@"title"];
        
        // 生成并添加图标
        UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 20, 20)];
        iconImageView.backgroundColor = [UIColor clearColor];
        
        // 生成图标
        CGSize iconSize = CGSizeMake(20, 20);
        UIGraphicsBeginImageContextWithOptions(iconSize, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [[UIColor whiteColor] setFill];
        CGContextSetLineWidth(context, 1.0);
        
        // 绘制三条水平线
        CGContextAddRect(context, CGRectMake(0, 4, 20, 3));
        CGContextAddRect(context, CGRectMake(0, 10, 20, 3));
        CGContextAddRect(context, CGRectMake(0, 16, 20, 3));
        CGContextFillPath(context);
        
        UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        iconImageView.image = iconImage;
        
        [header addSubview:iconImageView];
        
        // 标题
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(iconImageView.frame) + 10, 0, ScreenWidth - 100, header.frame.size.height)];
        titleLabel.text = title;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [header addSubview:titleLabel];
        
        // 更多按钮
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.frame = CGRectMake(ScreenWidth - 70, 0, 60, header.frame.size.height);
        [moreButton setTitle:@"更多>" forState:UIControlStateNormal];
        [moreButton setTitleColor:ColorWhiteAlpha60 forState:UIControlStateNormal];
        moreButton.titleLabel.font = [UIFont systemFontOfSize:14];
        moreButton.tag = indexPath.section;
        [moreButton addTarget:self action:@selector(moreButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [header addSubview:moreButton];
        
        return header;
    }
    
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 根据当前显示的页面类型设置不同的单元格大小
    if (_currentTabIndex == 0) { // "在追"页面
        // 在追页面每行3个，调整尺寸和间距
        CGFloat width = (ScreenWidth - 60) / 3.0;  // 左右各15间距，中间两个15间距
        return CGSizeMake(width, width * 1.5);
    } else { // "剧单"页面或其他页面
        // 剧单页面每行4个，每个section显示两行
        CGFloat width = (ScreenWidth - 80) / 4.0;  // 左右各15间距，间距10
        return CGSizeMake(width, width * 1.4);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (_currentTabIndex == 0) { // "在追"页面
        return CGSizeMake(0, 0); // 没有标题头
    } else {
        return CGSizeMake(ScreenWidth, 40);
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 处理点击事件
    NSString *videoTitle;
    
    if (_currentTabIndex == 0) {
        if (_followingSections.count > 0) {
            NSDictionary *followingData = _followingSections[0];
            NSArray *videos = followingData[@"videos"];
            videoTitle = videos[indexPath.item];
        } else {
            return;
        }
    } else {
        NSDictionary *sectionData = _videoSections[indexPath.section];
        NSArray *videos = sectionData[@"videos"];
        videoTitle = videos[indexPath.item];
    }
    
    NSLog(@"选择了视频: %@", videoTitle);
}

#pragma mark - Actions

- (void)moreButtonTapped:(UIButton *)sender {
    NSInteger section = sender.tag;
    NSDictionary *sectionData;
    NSString *title;
    
    // 在追页面不会调用这个方法，因为没有标题头
    sectionData = _videoSections[section];
    title = sectionData[@"title"];
    
    NSLog(@"点击了更多: %@", title);
}

- (void)searchButtonTapped:(UIButton *)sender {
    NSLog(@"点击了搜索按钮");
    
    // 创建弹窗提示
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"搜索"
                                                                             message:@"请输入要搜索的影片名称"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"输入影片名称";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *searchAction = [UIAlertAction actionWithTitle:@"搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *searchText = textField.text;
        
        if (searchText && searchText.length > 0) {
            NSLog(@"搜索内容: %@", searchText);
            // 此处添加实际搜索功能
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:searchAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)editButtonTapped:(UIButton *)sender {
    NSLog(@"点击了编辑按钮");
    // 这里可以添加编辑逻辑
}

#pragma mark - Utilities

- (UIImage *)generateSearchIcon {
    CGSize iconSize = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(iconSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(context, 2.0);
    
    // 绘制搜索图标
    CGFloat radius = 8.0;
    CGPoint center = CGPointMake(10, 10);
    
    // 绘制圆圈
    CGContextAddArc(context, center.x, center.y, radius, 0, 2 * M_PI, YES);
    CGContextStrokePath(context);
    
    // 绘制搜索柄
    CGContextMoveToPoint(context, center.x + radius * 0.7, center.y + radius * 0.7);
    CGContextAddLineToPoint(context, center.x + radius * 0.7 + 8, center.y + radius * 0.7 + 8);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)generatePencilIcon {
    CGSize iconSize = CGSizeMake(15, 15);
    UIGraphicsBeginImageContextWithOptions(iconSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setStroke];
    [[UIColor whiteColor] setFill];
    CGContextSetLineWidth(context, 1.0);
    
    // 绘制简单的铅笔图标
    CGContextMoveToPoint(context, 3, 12);
    CGContextAddLineToPoint(context, 6, 9);
    CGContextAddLineToPoint(context, 12, 3);
    CGContextAddLineToPoint(context, 9, 6);
    CGContextAddLineToPoint(context, 3, 12);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end 