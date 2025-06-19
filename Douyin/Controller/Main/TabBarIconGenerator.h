//
//  TabBarIconGenerator.h
//  Douyin
//
//  Created on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TabBarIconGenerator : NSObject

/**
 * 根据名称生成对应的标签图标
 * @param name 标签名称：首页、剧场、追剧、我的
 * @param selected 是否选中状态
 */
+ (UIImage *)generateIconWithName:(NSString *)name selected:(BOOL)selected;

@end 