//
//  SIWebProgressView.m
//  SIWebViewDemo
//
//  Created by Silence on 2017/10/10.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SIWebProgressView.h"

@implementation SIWebProgressView{
    CAShapeLayer *_shapeLayer;
    UIView *_progressBarView;
    CGFloat _fadeOutDelay;
}

#pragma mark -- 初始化
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 设置默认值
        _springSpeed = 0.4f;
        _duration = 0.5f;
        _springVelocity = 0.5f;
        _fadeOutDelay = 0.5f;
        self.userInteractionEnabled = NO;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _progressBarView = [[UIView alloc]initWithFrame:self.bounds];
        _progressBarView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        UIColor *tintColor = [UIColor colorWithRed:22.f / 255.f green:126.f / 255.f blue:251.f / 255.f alpha:1.0];
        if ([UIApplication.sharedApplication.delegate.window respondsToSelector:@selector(setTintColor:)] && UIApplication.sharedApplication.delegate.window.tintColor) {
            tintColor = UIApplication.sharedApplication.delegate.window.tintColor;
        }
        _progressBarView.backgroundColor = tintColor;
        _progressBarView.alpha = 0;
        [self addSubview:_progressBarView];
    }
    return self;
}

#pragma mark -- set
- (void)setColor:(UIColor *)color {
    _color = color;
    _progressBarView.backgroundColor = color;
}

- (void)setProgress:(NSProgress *)progress {
    _progress = progress;
    CGFloat fProgress = (CGFloat)progress.completedUnitCount/(CGFloat)progress.totalUnitCount;
    if (fProgress >= 1.0) {
        [UIView animateWithDuration:_duration delay:_fadeOutDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = _progressBarView.frame;
            frame.size.width = fProgress * self.bounds.size.width;
            _progressBarView.frame = frame;
        } completion:^(BOOL finished) {
            _progressBarView.alpha = 0.0;
            CGRect frame = _progressBarView.frame;
            frame.size.width = 0;
            _progressBarView.frame = frame;
        }];
    }else {
        _progressBarView.alpha = 1 ;
        [UIView animateWithDuration:_duration delay:0 usingSpringWithDamping:_springSpeed initialSpringVelocity:_springVelocity options:0 animations:^{
            CGRect frame = _progressBarView.frame;
            frame.size.width = fProgress * self.bounds.size.width;
            _progressBarView.frame = frame;
        } completion:nil];
    }
}


@end
