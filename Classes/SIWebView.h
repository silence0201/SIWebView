//
//  SIWebView.h
//  SIWebViewDemo
//
//  Created by Silence on 2017/10/10.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#import <WebKit/WebKit.h>
#endif

typedef NS_ENUM(NSInteger, SIWebViewNavigationType) {
    SIWebViewNavigationTypeLinkClicked,
    SIWebViewNavigationTypeFormSubmitted,
    SIWebViewNavigationTypeBackForward,
    SIWebViewNavigationTypeReload,
    SIWebViewNavigationTypeFormResubmitted,
    SIWebViewNavigationTypeOther
};

@class SIWebView;
@protocol SIWebViewDelegate <NSObject>

@optional
- (BOOL)webView:(SIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(SIWebViewNavigationType)navigationType;
- (void)webView:(SIWebView *)webVie updateProgress:(NSProgress *)progress;
- (void)webView:(SIWebView *)webView withError:(NSError *)error;
- (void)webViewDidFinshLoad:(SIWebView *)webView;
- (void)webViewDidStartLoad:(SIWebView *)webView;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;
#endif

- (NSArray <NSString *>*)registerJavascriptName;
- (NSObject *)registerJavaScriptHandler;

@end

@interface SIWebView : UIView

@property (nonatomic, readonly, copy) NSURL *URL;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly) NSProgress *estimatedProgress;

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIView *webView;// 默认是WKWebView

@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

- (instancetype)initWithUIWebView; // 可以使用UIWebView
- (instancetype)initWithUIWebView:(CGRect)frame;

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;
- (void)loadRequest:(NSURLRequest *)request;
- (void)loadUrl:(NSString *)url;
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL;

- (void)invokeJavaScript:(NSString *)function;
- (void)invokeJavaScript:(NSString *)function completionHandler:(void (^)(id, NSError * error))completionHandler;

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;

@end
