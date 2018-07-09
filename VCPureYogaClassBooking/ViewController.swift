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


class ViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    @IBOutlet weak var loadingPageIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var wkWebView: WKWebView!
    
    var html: String!
    var userName: String = "huohsien@gmail.com"
    var password: String = "jj121632"
    
    var isDebugingJavascript = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DDLogVerbose("begin")

        // positioning progress view
        progressView.frame = CGRect(x: 0, y: 88.0, width: view.bounds.size.width, height: 2.0)
        
        setupWebView()
        loadWKWebView()
    }

    // MARK: - web view operations
    
    private func setupWebView() {
        DDLogVerbose("begin")

        let contentController = WKUserContentController()
        let userScript = WKUserScript(
            source: """
                document.getElementById('username').value = \"\(userName)\";
                document.getElementById('password').value = \"\(password)\";

            """,
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(self, name: "loginState")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webViewRatio: CGFloat = 1.0
        wkWebView = WKWebView(frame: CGRect(x: 0.0, y: view.bounds.size.height * (1.0 - webViewRatio), width: view.bounds.size.width, height: view.bounds.size.height * webViewRatio), configuration: config)
        wkWebView.navigationDelegate = self
        wkWebView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        wkWebView.alpha = 0.0
        self.view.addSubview(wkWebView)
        self.view.bringSubview(toFront: progressView)
    }
    
    func loadWKWebView() {
        DDLogVerbose("begin")

        guard let url = URL(string: Constants.baseUrl) else {
            DDLogError("failed to create url")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        wkWebView.load(urlRequest)
        loadingPageIndicator.startAnimating()
    }
    
    //MARK: - webkit callbacks
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DDLogVerbose("begin")

        let urlString = wkWebView.url!.absoluteString
        DDLogVerbose("urlString=\(urlString)")
        
        loadingPageIndicator.stopAnimating()
        loadingPageIndicator.hidesWhenStopped = true
        wkWebView.alpha = 1.0
        checkLoginState()
//        login()
    }
    
    //MARK: - web javascript related functions
    func checkLoginState() {
        DDLogVerbose("begin")
        
        let jsString = """
            webkit.messageHandlers.loginState.postMessage("hello");
        """
        
        wkWebView.evaluateJavaScript(jsString) { (result, error) in
            if let error = error {
                DDLogError("\(error)")
            } else {
                DDLogVerbose("posted message from web page")
            }
        }
    }
    
    func login() {
        DDLogVerbose("begin")

        let jsString = """
            document.getElementById('username').value = \"\(userName)\";
            document.getElementById('password').value = \"\(password)\";

        """
        
        wkWebView.evaluateJavaScript(jsString) { (result, error) in
            if let error = error {
                DDLogError("\(error)")
            } else {

                DDLogVerbose("fill the login info correctly")
        
                
//                let jsString1 = """
//                var myForm = document.getElementById('sign-in-form');
//                myForm.querySelector('input[type="submit"]').click();
//                var tmp = document.querySelectorAll('button[data-class-id="1401"]');
//                tmp[0].click();
//                """
                
                
                let jsString1 = """
                var myForm = document.getElementById('sign-in-form');
                myForm.querySelector('input[type="submit"]').click();
                """
                
                self.wkWebView.evaluateJavaScript(jsString1) { (result, error) in
                    if let error = error {
                        DDLogError("\(error)")
                    } else {
                        DDLogVerbose("submit the login form")

                    }
                }
            }
        }
    }
    
    
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "loginState" {
            DDLogVerbose("JavaScript is sending a message \(message.body)")
        }
    }
    
    
    
    //MARK: -
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            progressView.isHidden = wkWebView.estimatedProgress == 1
            progressView.setProgress(Float(wkWebView.estimatedProgress), animated: true)
        }
    }
}
