//
//  EmptyStateView.h
//  Douyin
//
//  Created on 2024.
//

#import <UIKit/UIKit.h>

@interface EmptyStateView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *actionButton;

/**
 * 初始化空状态视图
 * @param frame 视图的frame
 * @param image 要显示的图片
 * @param message 提示信息
 * @param buttonTitle 按钮标题，如果为nil则不显示按钮
 */
- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image message:(NSString *)message buttonTitle:(NSString *)buttonTitle;

@end 