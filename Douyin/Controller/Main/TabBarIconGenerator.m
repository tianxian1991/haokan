//
//  TabBarIconGenerator.m
//  Douyin
//
//  Created on 2024.
//

#import "TabBarIconGenerator.h"

@implementation TabBarIconGenerator

+ (UIImage *)generateIconWithName:(NSString *)name selected:(BOOL)selected {
    UIColor *color = selected ? ColorThemeYellow : ColorWhiteAlpha60;
    UIImage *image = nil;
    
    if ([name isEqualToString:@"首页"]) {
        image = [self generateHomeIconWithColor:color];
    } else if ([name isEqualToString:@"剧场"]) {
        image = [self generateTheaterIconWithColor:color];
    } else if ([name isEqualToString:@"追剧"]) {
        image = [self generateSeriesIconWithColor:color];
    } else if ([name isEqualToString:@"我的"]) {
        image = [self generateProfileIconWithColor:color];
    }
    
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+ (UIImage *)generateHomeIconWithColor:(UIColor *)color {
    // 绘制首页图标
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 绘制一个简单的房子图标
    [color setStroke];
    [color setFill];
    
    CGContextSetLineWidth(context, 2.0);
    
    // 绘制屋顶
    CGContextMoveToPoint(context, 12, 3);
    CGContextAddLineToPoint(context, 22, 11);
    CGContextAddLineToPoint(context, 19, 11);
    CGContextAddLineToPoint(context, 19, 21);
    CGContextAddLineToPoint(context, 5, 21);
    CGContextAddLineToPoint(context, 5, 11);
    CGContextAddLineToPoint(context, 2, 11);
    CGContextAddLineToPoint(context, 12, 3);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)generateTheaterIconWithColor:(UIColor *)color {
    // 绘制剧场图标
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setStroke];
    [color setFill];
    
    CGContextSetLineWidth(context, 2.0);
    
    // 绘制一个简单的视频播放图标
    CGContextAddRect(context, CGRectMake(3, 5, 18, 14));
    CGContextStrokePath(context);
    
    // 绘制播放三角形
    CGContextMoveToPoint(context, 10, 10);
    CGContextAddLineToPoint(context, 16, 12);
    CGContextAddLineToPoint(context, 10, 14);
    CGContextAddLineToPoint(context, 10, 10);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)generateSeriesIconWithColor:(UIColor *)color {
    // 绘制追剧图标
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setStroke];
    [color setFill];
    
    CGContextSetLineWidth(context, 2.0);
    
    // 绘制一个简单的星星图标
    CGFloat centerX = size.width / 2;
    CGFloat centerY = size.height / 2;
    CGFloat radius = 8;
    
    for (int i = 0; i < 5; i++) {
        CGFloat angle = i * 2 * M_PI / 5 - M_PI / 2;
        CGFloat x = centerX + radius * cos(angle);
        CGFloat y = centerY + radius * sin(angle);
        
        if (i == 0) {
            CGContextMoveToPoint(context, x, y);
        } else {
            CGContextAddLineToPoint(context, x, y);
        }
    }
    
    CGContextClosePath(context);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)generateProfileIconWithColor:(UIColor *)color {
    // 绘制我的图标
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setStroke];
    [color setFill];
    
    // 绘制头像圆圈
    CGContextAddEllipseInRect(context, CGRectMake(8, 4, 8, 8));
    CGContextFillPath(context);
    
    // 绘制身体部分
    CGContextAddArc(context, 12, 20, 8, 0, M_PI, YES);
    CGContextClosePath(context);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end 