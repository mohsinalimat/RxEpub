//
//  RxEpubWebView.swift
//  RxEpub
//
//  Created by zhoubin on 2018/4/3.
//

import UIKit
import WebKit
public class RxEpubWebView: WKWebView {
    var tapCallBack:(()->())? = nil
    let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    public convenience init(frame:CGRect = UIScreen.main.bounds) {
//        let jsFileURL = Bundle(for: RxEpubReader.self).url(forResource: "Bridge", withExtension: "js")!
//        let cssFileURL = Bundle(for: RxEpubReader.self).url(forResource: "Style", withExtension: "css")!
        let js = """
        var meta = document.createElement('meta');
        meta.setAttribute('name', 'viewport');
        meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
        document.getElementsByTagName('head')[0].appendChild(meta);
        
        var script = document.createElement('script');
        script.setAttribute('type', 'text/javascript');
        script.setAttribute('src', 'App://RxEpub/Bridge.js');
        
        document.getElementsByTagName('head')[0].appendChild(script);
        
        var link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('href', 'App://RxEpub/Style.css');
        
        document.getElementsByTagName('head')[0].appendChild(link);
        """
        //
        //script.setAttribute('src', '\(jsFilePath)');
        //script.innerHTML='\(jsStr)';
        //link.setAttribute('href', '\(cssFilePath)');
        //link.innerHTML='\(cssStr)';
//        alert(document.getElementsByTagName('head')[0].innerHTML);
        let uerScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        let controller = WKUserContentController()
        controller.addUserScript(uerScript)
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
//        config.preferences.minimumFontSize = 15
        config.processPool = WKProcessPool()
        
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = .init(rawValue: 0)
        } else {
            config.requiresUserActionForMediaPlayback = false
        }
        self.init(frame: frame, configuration: config)
        isOpaque = false
        uiDelegate = self
        navigationDelegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.clear
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            
        }
        indicator.hidesWhenStopped = true
        addSubview(indicator)
//        let tapgs = UITapGestureRecognizer(target: self, action: #selector(click))
//        tapgs.numberOfTapsRequired = 1
//        tapgs.delegate = self
//        addGestureRecognizer(tapgs)
    }
    
    @objc private func click(){
        tapCallBack?()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = self.center
    }
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func load(_ request: URLRequest) -> WKNavigation? {
        indicator.startAnimating()
        return super.load(request)
    }
}
//extension RxEpubWebView:UIGestureRecognizerDelegate{
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        return true
//    }
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//}
extension RxEpubWebView:WKUIDelegate,WKNavigationDelegate{
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    //Alert弹框
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.cancel) { (_) in
            completionHandler()
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //confirm弹框
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "温馨提示", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (_) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel) { (_) in
            completionHandler(false)
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    //TextInput弹框
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (_) in}
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (_) in
            completionHandler(alert.textFields?.last?.text)
        }
        alert.addAction(action)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFailnavigation:",error)
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        addCss()
        if RxEpubReader.shared.scrollDirection == .right {
            scrollsToBottom()
        }else{
            scrollsToTop()
        }
        indicator.stopAnimating()
    }
    func addCss(){

        evaluateJavaScript("addCSS('html','height: \(frame.size.height-30)px; -webkit-column-gap: 0px; -webkit-column-width: \(frame.size.width)px;')", completionHandler: nil)
        evaluateJavaScript("addCSS('html','font-size:\(RxEpubReader.shared.config.fontSize.value * 4.0/3.0)px')", completionHandler: nil)
        evaluateJavaScript("addCSS('html','color:\(RxEpubReader.shared.config.textColor.value)')", completionHandler: nil)
        evaluateJavaScript("addCSS('a','color:\(RxEpubReader.shared.config.textColor.value)')", completionHandler: nil)
        if let imageName = RxEpubReader.shared.config.backgroundImage.value {
            evaluateJavaScript("addCSS('html','background-image:url(App://RxEpub/\(imageName).jpg);background-size: 100% \(frame.size.height)px;')")
        }
    }
    
    func scrollsToBottom(){
        let js = """
            var width = document.body.scrollWidth
            window.scrollTo (width, 0);
            """
        evaluateJavaScript(js, completionHandler: nil)
    }
    func scrollsToTop(){
        let js = """
            window.scrollTo (0, 0);
            """
        evaluateJavaScript(js, completionHandler: nil)
    }
}
