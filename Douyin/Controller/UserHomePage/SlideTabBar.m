//
//  SlideTabBar.m
//  Douyin
//
//  Created by Qiao Shi on 2018/10/22.
//  Copyright © 2018 Qiao Shi. All rights reserved.
//

#import "SlideTabBar.h"
#import <objc/runtime.h>

@interface SlideTabBar ()

@property (nonatomic, strong) UIView                           *slideLightView;
@property (nonatomic, strong) NSMutableArray<UILabel *>        *labels;
@property (nonatomic, strong) NSMutableArray<NSString *>       *titles;
@property (nonatomic, assign) NSInteger                        tabIndex;
@property (nonatomic, assign) CGFloat                          itemWidth;

@end

@implementation SlideTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _labels = [NSMutableArray array];
        _titles = [NSMutableArray array];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    if(_titles.count == 0) {
        return;
    }
    
    [[self subviews] enumerateObjectsUsingBlock:^(UIView *subView, NSUInteger idx, BOOL *stop) {
        [subView removeFromSuperview];
    }];
    [_labels removeAllObjects];
    
    // 计算更紧凑的间距，实现图片中的样式
    CGFloat totalWidth = 0;
    CGFloat padding = 20; // 标签间的间距
    
    // 先计算所有标签的总宽度
    NSMutableArray *labelWidths = [NSMutableArray array];
    CGFloat availableWidth = self.bounds.size.width;
    
    for (NSString *title in _titles) {
        CGSize textSize = [title sizeWithAttributes:@{NSFontAttributeName: BigFont}];
        [labelWidths addObject:@(textSize.width)];
        totalWidth += textSize.width;
    }
    
    // 分配标签位置
    CGFloat startX = (availableWidth - totalWidth - padding * (_titles.count - 1)) / 2;
    if (startX < 0) startX = 0;
    
    // 创建标签
    __block CGFloat currentX = startX;
    [_titles enumerateObjectsUsingBlock:^(NSString * title, NSUInteger idx, BOOL *stop) {
        UILabel *label = [[UILabel alloc]init];
        label.text = title;
        label.textColor = ColorWhiteAlpha60;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = BigFont;
        label.tag = idx;
        label.userInteractionEnabled = YES;
        [label addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTapAction:)]];
        
        CGFloat width = [labelWidths[idx] floatValue];
        label.frame = CGRectMake(currentX, 0, width, self.bounds.size.height);
        currentX += width + padding;
        
        [self.labels addObject:label];
        [self addSubview:label];
        
        // 移除分隔线，图片中没有显示分隔线
    }];
    _labels[_tabIndex].textColor = [UIColor whiteColor]; // 选中标签使用纯白色
    
    // 调整下划线位置和颜色
    CGFloat underlineWidth = [labelWidths[_tabIndex] floatValue];
    CGFloat underlineX = 0;
    
    // 计算当前选中标签的X位置
    for (int i = 0; i < _tabIndex; i++) {
        underlineX += [labelWidths[i] floatValue] + padding;
    }
    underlineX += startX;
    
    _slideLightView = [[UIView alloc] init];
    _slideLightView.backgroundColor = [UIColor whiteColor]; // 使用白色下划线
    _slideLightView.frame = CGRectMake(underlineX, self.bounds.size.height-2, underlineWidth, 2);
    [self addSubview:_slideLightView];
    
    // 存储每个标签的宽度和位置，用于点击动画
    objc_setAssociatedObject(self, "labelWidths", labelWidths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, "labelPadding", @(padding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, "startX", @(startX), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setLabels:(NSArray<NSString *> *)titles tabIndex:(NSInteger)tabIndex {
    [_titles removeAllObjects];
    [_titles addObjectsFromArray:titles];
    _tabIndex = tabIndex;
}

- (void)onTapAction:(UITapGestureRecognizer *)sender {
    NSInteger index = sender.view.tag;
    if(_delegate) {
        // 获取存储的标签宽度和位置信息
        NSArray *labelWidths = objc_getAssociatedObject(self, "labelWidths");
        CGFloat padding = [objc_getAssociatedObject(self, "labelPadding") floatValue];
        CGFloat startX = [objc_getAssociatedObject(self, "startX") floatValue];
        
        if (labelWidths) {
            // 计算选中标签的X位置
            CGFloat underlineX = startX;
            for (int i = 0; i < index; i++) {
                underlineX += [labelWidths[i] floatValue] + padding;
            }
            
            // 获取选中标签的宽度
            CGFloat underlineWidth = [labelWidths[index] floatValue];
            
            [UIView animateWithDuration:0.10
                                  delay:0
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 // 更新下划线位置
                                 CGRect frame = self.slideLightView.frame;
                                 frame.origin.x = underlineX;
                                 frame.size.width = underlineWidth;
                                 [self.slideLightView setFrame:frame];
                                 
                                 // 更新标签颜色
                                 [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                                     label.textColor = index == idx ? [UIColor whiteColor] : ColorWhiteAlpha60;
                                 }];
                             } completion:^(BOOL finished) {
                                 [self.delegate onTabTapAction:index];
                             }];
        }
    }
}

@end
