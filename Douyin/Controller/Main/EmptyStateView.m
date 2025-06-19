//
//  EmptyStateView.m
//  Douyin
//
//  Created on 2024.
//

#import "EmptyStateView.h"

@implementation EmptyStateView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image message:(NSString *)message buttonTitle:(NSString *)buttonTitle {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = ColorThemeBackground;
        
        // 创建图片视图
        _imageView = [[UIImageView alloc] init];
        _imageView.image = image;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];
        
        // 创建消息标签
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.text = message;
        _messageLabel.textColor = ColorWhiteAlpha60;
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = SmallFont;
        [self addSubview:_messageLabel];
        
        // 如果提供了按钮标题，创建按钮
        if (buttonTitle && buttonTitle.length > 0) {
            _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_actionButton setTitle:buttonTitle forState:UIControlStateNormal];
            [_actionButton setTitleColor:ColorWhite forState:UIControlStateNormal];
            _actionButton.titleLabel.font = SmallFont;
            _actionButton.backgroundColor = ColorThemeRed;
            _actionButton.layer.cornerRadius = 20;
            _actionButton.layer.masksToBounds = YES;
            [self addSubview:_actionButton];
        }
        
        [self setupLayout];
    }
    return self;
}

- (void)setupLayout {
    // 设置图片位置在视图中心偏上
    CGFloat imageWidth = 120;
    CGFloat imageHeight = 120;
    _imageView.frame = CGRectMake((self.frame.size.width - imageWidth) / 2,
                                 self.frame.size.height / 3 - imageHeight / 2,
                                 imageWidth,
                                 imageHeight);
    
    // 设置消息标签位置在图片下方
    _messageLabel.frame = CGRectMake(20,
                                    CGRectGetMaxY(_imageView.frame) + 15,
                                    self.frame.size.width - 40,
                                    20);
    
    // 设置按钮位置在消息标签下方
    if (_actionButton) {
        _actionButton.frame = CGRectMake((self.frame.size.width - 120) / 2,
                                       CGRectGetMaxY(_messageLabel.frame) + 20,
                                       120,
                                       40);
    }
}

@end 