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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.black
        webView.allowsBackForwardNavigationGestures = true
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
        webView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        view.addSubview(webView)
        print("Bounds: \(view.bounds) | Nav: \(navigationController!.navigationBar.frame.height)")
        
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
