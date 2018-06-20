//
//  ViewController.swift
//  VCPureYogaClassBooking
//
//  Created by victor on 2018/5/26.
//  Copyright © 2018 VHHC Studio. All rights reserved.
//

import UIKit
import Kanna
import WebKit
import CocoaLumberjack


class ViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var loadingPageIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var wkWebView: WKWebView!
    
    var html: String!
    var userName: String = "huohsien@gmail.com"
    var password: String = "jj121632"
    
    var isDebugingJavascript = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // positioning progress view
        progressView.frame = CGRect(x: 0, y: 88.0, width: view.bounds.size.width, height: 2.0)
        
        loadWKWebView()
    }

    // MARK: - web view operations
    
    func loadWKWebView() {
        
        let webViewRatio: CGFloat = 1.0
        wkWebView = WKWebView(frame: CGRect(x: 0.0, y: view.bounds.size.height * (1.0 - webViewRatio), width: view.bounds.size.width, height: view.bounds.size.height * webViewRatio))
        wkWebView.navigationDelegate = self
        wkWebView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        wkWebView.alpha = 0.0
        self.view.addSubview(wkWebView)
        self.view.bringSubview(toFront: progressView)

        guard let url = URL(string: Constants.baseUrl) else {
            DDLogError("failed to create url")
            return
        }
        
//        setupJSDebug()

        let urlRequest = URLRequest(url: url)
        wkWebView.load(urlRequest)
        loadingPageIndicator.startAnimating()
    }
    
    //MARK: - webkit callbacks
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        let urlString = wkWebView.url!.absoluteString
        DDLogVerbose("urlString=\(urlString)")
        
//        if urlString.hasPrefix("log://") {
//            // print log of javascript
//            if isDebugingJavascript {
//                let str = wkWebView.url!.absoluteString
//                if let index = str.range(of: "log://")?.upperBound {
//                    let dataString: String = "\(str[index...])"
//                    print("js debug: \(self),\(dataString.removingPercentEncoding!)")
//                    return
//                }
//            }
//        }
        
        loadingPageIndicator.stopAnimating()
        loadingPageIndicator.hidesWhenStopped = true
        wkWebView.alpha = 1.0
        
        login()
    }
    
    //MARK: - web javascript related functions
    func login() {
        
//        let jsString = """
//        document.getElementById('username').value = \"\(userName)\";
//        document.getElementById('password').value = \"\(password)\";
//        document.location.href = "log://1234";
//        """

        let jsString = """
            document.getElementById('username').value = \"\(userName)\";
            document.getElementById('password').value = \"\(password)\";
        """
        
        wkWebView.evaluateJavaScript(jsString) { (result, error) in
            if let error = error {
                DDLogError("\(error)")
            }
        }
        


    }
    
//    func setupJSDebug() {
//
//        wkWebView.evaluateJavaScript("""
//            function log( text ) {
//                location.href = "log://"+text;
//            }
//        """) { (result, error) in
//            if let error = error {
//                DDLogError("\(error)")
//            }
//        }
//
//    }
    
    
    
    //MARK: -
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.isHidden = wkWebView.estimatedProgress == 1
            progressView.setProgress(Float(wkWebView.estimatedProgress), animated: true)
        }
    }
    //MARK: - html parser
    
    func fetchAndUpdateData() {
        
        // get the result of the requested page
        wkWebView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (result, error) in
            
            self.html = result as! String
            
            // parsing
            do {
                let doc = try HTML(html: self.html, encoding: .utf8)
                
                for tr in doc.xpath("//tbody/tr") {
                    for td in tr.xpath("./td") {
                        guard let locationNameString: String = td.text else {continue}
                        //                        print(locationNameString)
                        if locationNameString == "臺灣大學" || locationNameString == "大安森林" {
                            
                            
                            let dateTime = tr.xpath("./td[3]")
                            
                            if let node = dateTime.first {
                                if let dateTimeString: String = node.content {
                                    
                                    if dateTimeString.contains("儀器")  {
                                        continue
                                    }
                                  
                                    return
                                }
                            }
                        }
                    }
                }
                
            } catch {/* error handling here */}
        }
    }
}

