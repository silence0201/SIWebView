//
//  SIWebView.m
//  SIWebViewDemo
//
//  Created by Silence on 2017/10/10.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SIWebView.h"
#import "SIWebProgress.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
@interface SIWebView ()<UIWebViewDelegate,SIWebViewProgressDelegate,WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler>
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong) WebViewJavascriptBridge* javascriptBridge;
@property (nonatomic, strong) SIWebViewProress *progessProxy;
@property (nonatomic, strong) NSProgress *estimatedProgress;
#else
@interface SIWebView()<SIWebViewProgressDelegate,UIWebViewDelegate,CHWebViewProgressDelegate>
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong) WebViewJavascriptBridge* javascriptBridge;
#endif
@end

@implementation SIWebView

- (instancetype)init {
    if (self = [super init]) {
        _webView = [[WKWebView alloc]initWithFrame:CGRectZero configuration:[self configuretion]];
        if (_webView) {
            [self initWKWebView:(WKWebView *)_webView];
        }else {
            _webView = [[UIWebView alloc]init];
            [self initUIWebView:(UIWebView *)_webView];
        }
    }
    return self;
}

- (instancetype)initWithUIWebView {
    if (self = [super init]) {
        _webView = [[UIWebView alloc]init];
        [self initUIWebView:(UIWebView *)_webView];
    }
    return self;
}

- (instancetype)initWithUIWebView:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _webView = [[UIWebView alloc]initWithFrame:frame];
        [self initUIWebView:(UIWebView *)_webView];
    }
    return self;
}

- (void)loadUrl:(NSString *)url {
    NSURLRequest *rquest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self loadRequest:rquest];
}

- (void)loadRequest:(NSURLRequest *)request {
    SEL selector = NSSelectorFromString(@"loadRequest:");
    if ([_webView respondsToSelector:selector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            IMP imp = [_webView methodForSelector:selector];
            void (*func)(id, SEL, NSURLRequest *) = (void *)imp;
            func(_webView, selector,request);
        });
    }
}

- (void)loadHTMLString:(  NSString *)string baseURL:(NSURL *)baseURL{
    SEL selector = NSSelectorFromString(@"loadHTMLString:baseURL:");
    if ([_webView respondsToSelector:selector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            IMP imp = [_webView methodForSelector:selector];
            void (*func)(id, SEL, NSString *,NSURL *) = (void *)imp;
            func(_webView, selector,string,baseURL);
        });
    }
}

- (void)invokeJavaScript:(NSString *)function {
    [self invokeJavaScript:function completionHandler:nil];
}

- (void)invokeJavaScript:(NSString *)function completionHandler:(void (^)(id, NSError *))completionHandler {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)_webView;
        [webView evaluateJavaScript:function completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(result,error);
            }
        }];
    }else{
        [self.context evaluateScript:function];
    }
}

- (void)invokeName:(NSString *)name{
    SEL selector = NSSelectorFromString(name);
    if ([_webView respondsToSelector:selector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            IMP imp = [_webView methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(_webView, selector);
        });
        
    }
}

#pragma mark -- 常用方法
- (BOOL)canGoBack{
    if ([self isWKWebView]) {
        WKWebView *wk = (WKWebView *)_webView;
        return wk.canGoBack;
    }else{
        UIWebView *wk = (UIWebView *)_webView;
        return wk.canGoBack;
    }
}
- (BOOL)canGoForward{
    if ([self isWKWebView]) {
        WKWebView *wk = (WKWebView *)_webView;
        return wk.canGoForward;
    }else{
        UIWebView *wk = (UIWebView *)_webView;
        return wk.canGoForward;
    }
}

- (void)reload{
    [self invokeName:@"reload"];
}
- (void)stopLoading{
    [self invokeName:@"stopLoading"];
}
- (void)goBack{
    [self invokeName:@"goBack"];
}
- (void)goForward{
    [self invokeName:@"goForward"];
}


#pragma mark -- Private
- (void)initWKWebView:(WKWebView *)webView {
    webView.allowsBackForwardNavigationGestures = YES;
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.backgroundColor = [UIColor whiteColor];
    [self addSubview:webView];
    [self registerKVO];
    [self layout];
}

- (void)initUIWebView:(UIWebView *)webView {
    _progessProxy = [[SIWebViewProress alloc]init];
    _progessProxy.webViewProxyDelegate = self;
    _progessProxy.progressDelegate = self;
    webView.delegate = _progessProxy;
    webView.backgroundColor = [UIColor whiteColor];
    [self addSubview:webView];
    [self layout];
}

- (BOOL)isWKWebView {
    return [_webView isKindOfClass:[WKWebView class]];
}

- (void)layout {
    [_webView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    NSLayoutConstraint *contraint1 = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    NSLayoutConstraint *contraint2 = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *contraint3 = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *contraint4 = [NSLayoutConstraint constraintWithItem:_webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    
    // 将约束添加到父视图上
    [self addConstraints:@[contraint1,contraint2,contraint3,contraint4]];
}

-(void)updateWebView {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)_webView;
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:100];
        [progress setCompletedUnitCount:webView.estimatedProgress];
        if ([self.delegate respondsToSelector:@selector(webView:updateProgress:)]) {
            [self.delegate webView:self updateProgress:progress];
        }
    }
}

- (void)invokeIMPFunction:(id)body name:(NSString *)name{
    NSObject *observe  = [self.delegate registerJavaScriptHandler];
    if (observe) {
        SEL selector;
        BOOL isParameter = YES;
        if ([body isKindOfClass:[NSString class]]) {
            isParameter = ![body isEqualToString:@""];
        }
        if ( isParameter && body) {
            selector = NSSelectorFromString([name stringByAppendingString:@":"]);
        }else{
            selector = NSSelectorFromString(name);
        }
        if ([observe respondsToSelector:selector]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                IMP imp = [observe methodForSelector:selector];
                if (body) {
                    void (*func)(id, SEL, id) = (void *)imp;
                    func(observe, selector,body);
                }else{
                    void (*func)(id, SEL) = (void *)imp;
                    func(observe, selector);
                }
            });
            
        }
    }
    
}


#pragma mark -- WKWebView Delegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if ([self.delegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.delegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    BOOL decision = YES;
    if ([self.delegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        decision = [self.delegate webView:self shouldStartLoadWithRequest:navigationAction.request navigationType:(SIWebViewNavigationType)navigationAction.navigationType];
    }
    if (decision) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    WKWebView *web = (WKWebView *)_webView;
    webView.configuration.userContentController = [[WKUserContentController alloc] init];
    // 注册js脚本
    if ([self.delegate respondsToSelector:@selector(registerJavascript)]) {
        NSDictionary *registerJavascript = [self.delegate registerJavascript];
        [registerJavascript.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            [web.configuration.userContentController removeScriptMessageHandlerForName:name];
            [web.configuration.userContentController addScriptMessageHandler:self name:name];
        }];
    }

    if ([self.delegate respondsToSelector:@selector(webViewDidFinshLoad:)]) {
        [self.delegate webViewDidFinshLoad:self];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self withError:error];
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self invokeIMPFunction:message.body name:message.name];
}

#pragma mark -- UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate webView:self shouldStartLoadWithRequest:request navigationType:(SIWebViewNavigationType)navigationType];
    }else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if([self.delegate respondsToSelector:@selector(registerJavascript)]){
        self.context=[webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        NSDictionary *registerJavascript = [self.delegate registerJavascript];
        [registerJavascript.allKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            __weak typeof(self) weakSelf = self;
            self.context[name] = ^(id body){
                NSString *selName = [registerJavascript valueForKey:name];
                if (selName) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf invokeIMPFunction:body name:registerJavascript[name]];
                }

            };
        }];
    }
    
    
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinshLoad:self];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(webView:withError:)]) {
        [self.delegate webView:self withError:error];
    }
}

#pragma mark -- SIWebViewProgress Delegate
- (void)updateProgress:(NSProgress *)progress webViewProgress:(SIWebViewProress *)webViewProgress {
    if ([self.delegate respondsToSelector:@selector(webView:updateProgress:)]) {
        self.estimatedProgress = progress;
        [self.delegate webView:self updateProgress:progress];
    }
}

#pragma mark -- Get/Set
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.frame = self.bounds;
}

- (WKWebViewConfiguration *)configuretion {
    WKWebViewConfiguration *cofig = [[WKWebViewConfiguration alloc]init];
    cofig.preferences = [[WKPreferences alloc]init];
    cofig.preferences.minimumFontSize = 10;
    cofig.preferences.javaScriptEnabled = YES;
    cofig.processPool = [[WKProcessPool alloc]init];
    // 默认不能通过js自动打开窗口,必须通过用户交互才能打开
    cofig.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    return cofig;
}

- (NSString *)title {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)_webView;
        return webView.title;
    }else {
        UIWebView *webView = (UIWebView *)_webView;
        return [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
}

- (NSURL *)URL {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)_webView;
        return webView.URL;
    }else {
        UIWebView *webView = (UIWebView *)_webView;
        return webView.request.URL;
    }
}

- (NSProgress *)estimatedProgress {
    if ([self isWKWebView]) {
        WKWebView *webView = (WKWebView *)_webView;
        NSProgress *progress = [NSProgress progressWithTotalUnitCount:100];
        [progress setCompletedUnitCount:webView.estimatedProgress*100];
        return progress;
    }else {
        return _estimatedProgress;
    }
}

#pragma mark -- KVO

- (NSArray<NSString *> *)keyPaths {
    return  @[@"title",@"estimatedProgress"];
}

- (void)registerKVO {
    for (NSString *keyPath in [self keyPaths]) {
        [_webView addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)unregisterKVO {
    for (NSString *keyPath in [self keyPaths]) {
        [_webView removeObserver:self  forKeyPath:keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateWebView) withObject:nil waitUntilDone:NO];
    }else {
        [self updateWebView];
    }
}

#pragma mark -- 支持WebViewJavascriptBridge相关函数
- (void)initializeJavascriptBridge {
    [self initializeJavascriptBridge:NO];
}


- (void)initializeJavascriptBridge:(BOOL)enableLogging {
    if (enableLogging) {
        [WebViewJavascriptBridge enableLogging];
    }
    self.javascriptBridge = [WebViewJavascriptBridge bridgeForWebView:_webView];
    [self.javascriptBridge setWebViewDelegate:self];
}

- (void)registerHandler:(NSString *)handlerName handler:(SIJBHandler)handler {
    if (self.javascriptBridge) {
        [self.javascriptBridge registerHandler:handlerName handler:handler];
    }
}

- (void)removeHandler:(NSString *)handlerName {
    if (self.javascriptBridge) {
        [self.javascriptBridge removeHandler:handlerName];
    }
}

-(void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(SIJBResponseCallback)responseCallback {
    if (self.javascriptBridge) {
        [self.javascriptBridge callHandler:handlerName data:data responseCallback:responseCallback];
    }
}

@end
