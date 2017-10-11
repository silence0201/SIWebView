//
//  SIWebProgressView.m
//  SIWebViewDemo
//
//  Created by Silence on 2017/10/10.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SIWebProgressView.h"

static  NSString *completeURL = @"webviewprogressproxy:///complete";
const float InitialProgressValue = 0.1f;
const float InteractiveProgressValue = 0.5f;
const float FinalProgressValue = 0.9f;

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

@interface SIWebViewProress ()

@property (nonatomic, strong) NSProgress *currentProgress;

@end

@implementation SIWebViewProress {
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
    float _progress;
}

- (instancetype)init {
    if (self = [super init]) {
        _maxLoadCount = 0;
        _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

#pragma mark -- Private
- (void)setProgress:(float)progress{
    if (progress > _progress ) {
        _progress = progress;
        [self.currentProgress setCompletedUnitCount:_progress*100];
        if ([_progressDelegate respondsToSelector:@selector(updateProgress:webViewProgress:)]) {
            [_progressDelegate updateProgress:self.currentProgress webViewProgress:self];
        }
    }
}

- (void)startProgress{
    if (_progress < InitialProgressValue) {
        [self setProgress:InitialProgressValue];
    }
}

- (void)incrementProgress{
    float progress = _progress;
    float maxProgress = _interactive ? FinalProgressValue : InteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress{
    [self setProgress:1.0];
}

- (void)reset{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}
- (NSProgress *)currentProgress{
    if(!_currentProgress){
        _currentProgress = [NSProgress progressWithTotalUnitCount:100];
    }
    return _currentProgress;
}

#pragma mark -- UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString isEqualToString:completeURL]) {
        [self completeProgress];
        return NO;
    }
    
    BOOL ret = YES;
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        ret = [_webViewProxyDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (ret && !isFragmentJump && isHTTP && isTopLevelNavigation) {
        _currentURL = request.URL;
        [self reset];
    }
    return ret;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_webViewProxyDelegate webViewDidStartLoad:webView];
    }
    
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
    [self startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_webViewProxyDelegate webViewDidFinishLoad:webView];
    }
    _loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if ([_webViewProxyDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_webViewProxyDelegate webView:webView didFailLoadWithError:error];
    }
    
    _loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

#pragma mark -- Rewrite
- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    
    if ([self.webViewProxyDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        if ([_webViewProxyDelegate respondsToSelector:aSelector]) {
            return [(NSObject *)_webViewProxyDelegate methodSignatureForSelector:aSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_webViewProxyDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_webViewProxyDelegate];
    }
}

@end


