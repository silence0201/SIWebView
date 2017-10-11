//
//  SIWebProgressView.h
//  SIWebViewDemo
//
//  Created by Silence on 2017/10/10.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIWebProgressView : UIView

@property (nonatomic, assign) CGFloat springVelocity;
@property (nonatomic, assign) CGFloat springSpeed;
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) UIColor *color;

@end

@protocol SIWebViewProgressDelegate;

@interface SIWebViewProress : NSObject<UIWebViewDelegate>
@property (nonatomic, readonly) NSProgress *currentProgress; // 0.0...1.0
@property (nonatomic, weak) id<SIWebViewProgressDelegate> progressDelegate;
@property (nonatomic, weak) id<UIWebViewDelegate> webViewProxyDelegate;

@end

@protocol SIWebViewProgressDelegate <NSObject>
@optional
- (void)updateProgress:(NSProgress *)progress webViewProgress:(SIWebViewProress *)webViewProgress;
@end
