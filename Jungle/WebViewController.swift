//
//  WebViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-26.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    var webView:WKWebView!
    
    var urlString:String!
    var shouldAddBackdrop = false
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)

        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.black
        webView.allowsBackForwardNavigationGestures = true
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
        
        if shouldAddBackdrop {
            
            self.addNavigationBarBackdrop()
            let navHeight = self.navigationController!.navigationBar.frame.height + 20.0
            webView.frame = CGRect(x: 0, y: navHeight, width: view.bounds.width, height: view.bounds.height - navHeight)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
            webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        }
        view.addSubview(webView)
        
    }
    
    func handleDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
    
    
    func addDoneButton() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    func done() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
