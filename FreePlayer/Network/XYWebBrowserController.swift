//
//  WebBrowserViewController.swift
//  FreePlayer
//
//  Created by CXY on 2019/2/21.
//  Copyright © 2019年 cxy. All rights reserved.
//

import UIKit
import WebKit

public protocol XYWebBrowserControllerDelegate: class {
    func didStartLoading()
    func didFinishLoading(success: Bool)
}

class XYWebBrowserController: BaseViewController {
    @IBOutlet weak var container: UIView!
    
    public weak var delegate: XYWebBrowserControllerDelegate?
    var storedStatusColor: UIBarStyle?
    var buttonColor: UIColor? = nil
    var titleColor: UIColor? = nil
    var closing: Bool = false
    
    private lazy var backBarButtonItem: UIBarButtonItem =  {
        var tempBackBarButtonItem = UIBarButtonItem(image: XYWebBrowserController.bundledImage(named: "SwiftWebVCBack"),
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(goBackTapped(_:)))
        tempBackBarButtonItem.width = 18.0
        tempBackBarButtonItem.tintColor = buttonColor
        return tempBackBarButtonItem
    }()
    
    private lazy var forwardBarButtonItem: UIBarButtonItem =  {
        var tempForwardBarButtonItem = UIBarButtonItem(image: XYWebBrowserController.bundledImage(named: "SwiftWebVCNext"),
                                                       style: .plain,
                                                       target: self,
                                                       action: #selector(goForwardTapped(_:)))
        tempForwardBarButtonItem.width = 18.0
        tempForwardBarButtonItem.tintColor = buttonColor
        return tempForwardBarButtonItem
    }()
    
    private lazy var refreshBarButtonItem: UIBarButtonItem = {
        var tempRefreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                       target: self,
                                                       action: #selector(reloadTapped(_:)))
        tempRefreshBarButtonItem.tintColor = buttonColor
        return tempRefreshBarButtonItem
    }()
    
    private lazy var stopBarButtonItem: UIBarButtonItem = {
        var tempStopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                    target: self,
                                                    action: #selector(stopTapped(_:)))
        tempStopBarButtonItem.tintColor = buttonColor
        return tempStopBarButtonItem
    }()
    
    private lazy var actionBarButtonItem: UIBarButtonItem = {
        var tempActionBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                      target: self,
                                                      action: #selector(actionButtonTapped(_:)))
        tempActionBarButtonItem.tintColor = buttonColor
        return tempActionBarButtonItem
    }()
    
    
    private lazy var webView: WKWebView = {
        var webView = WKWebView(frame: UIScreen.main.bounds)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }()
    
    private lazy var tilteView: UITextField = {
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width-60, height: 30))
        field.font = UIFont.systemFont(ofSize: 12)
        field.textColor = UIColor.black
        field.leftViewMode = .always
        let placeholder = "搜索或输入网站名称"
        let attributedString = NSMutableAttributedString(string: placeholder)
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], range: NSRange(location: 0, length: placeholder.count))
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)], range: NSRange(location: 0, length: placeholder.count))
        field.attributedPlaceholder = attributedString
        field.keyboardType = .URL
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .go
        field.delegate = self
        field.borderStyle = .roundedRect
        return field
    }()
    
    
    private var request: URLRequest!
    
    var navBarTitle: UILabel!
    
    var sharingEnabled = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        container.addSubview(webView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: tilteView)
        
//        if let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow, let statusBar = statusBarWindow.value(forKey: "statusBar") as? UIView {
//            statusBar.backgroundColor = XYConst.commonBgColor
//        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        webView.frame = container.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        assert(self.navigationController != nil, "SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.")
        
        updateToolbarItems()
        navBarTitle = UILabel()
        navBarTitle.backgroundColor = UIColor.clear
        if presentingViewController == nil {
            if let titleAttributes = navigationController!.navigationBar.titleTextAttributes {
                navBarTitle.textColor = titleAttributes[.foregroundColor] as? UIColor
            }
        } else {
            navBarTitle.textColor = self.titleColor
        }
        navBarTitle.shadowOffset = CGSize(width: 0, height: 1);
        navBarTitle.font = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        navBarTitle.textAlignment = .center
        navigationItem.titleView = navBarTitle;
        
        super.viewWillAppear(true)

        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            self.navigationController?.setToolbarHidden(false, animated: false)
        } else if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        webView.stopLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
    }
    
    // MARK: Toolbar
    func updateToolbarItems() {
        backBarButtonItem.isEnabled = webView.canGoBack
        forwardBarButtonItem.isEnabled = webView.canGoForward
        
        let refreshStopBarButtonItem: UIBarButtonItem = webView.isLoading ? stopBarButtonItem : refreshBarButtonItem
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let toolbarWidth: CGFloat = 250.0
            fixedSpace.width = 35.0
            
            let items = sharingEnabled ? [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem, fixedSpace, actionBarButtonItem] : [fixedSpace, refreshStopBarButtonItem, fixedSpace, backBarButtonItem, fixedSpace, forwardBarButtonItem]
            
            let toolbar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: toolbarWidth, height: 44.0))
    
            if !closing {
                toolbar.items = items
                if presentingViewController == nil {
                    toolbar.barTintColor = navigationController!.navigationBar.barTintColor
                } else {
                    toolbar.barStyle = navigationController!.navigationBar.barStyle
                }
                toolbar.tintColor = navigationController!.navigationBar.tintColor
            }
            navigationItem.rightBarButtonItems = items.reversed()
        } else {
            let items = sharingEnabled ? [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, actionBarButtonItem, fixedSpace] : [fixedSpace, backBarButtonItem, flexibleSpace, forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, fixedSpace]
            
            if let navigationController = navigationController, !closing {
                if presentingViewController == nil {
                    navigationController.toolbar.barTintColor = navigationController.navigationBar.barTintColor
                } else {
                    navigationController.toolbar.barStyle = navigationController.navigationBar.barStyle
                }
                navigationController.toolbar.tintColor = navigationController.navigationBar.tintColor
                toolbarItems = items
            }
        }
    }
    
    private func loadingRequest(address: String) {
        guard !address.isEmpty else {
            return
        }
        var loc = ""
        if !address.lowercased().hasPrefix("http://") || !address.lowercased().hasPrefix("https://") {
            loc = "http://".appending(address)
        }
        if let url = URL(string: loc) {
            webView.load(URLRequest(url: url))
        }
    }
    
    // MARK: Actions
    
    @IBAction func navBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
        navigationController?.isNavigationBarHidden = false
    }

    @IBAction func browse(_ sender: UIButton) {
        view.endEditing(true)
        if let text = tilteView.text {
            loadingRequest(address: text)
        }
    }
    
    @objc func goBackTapped(_ sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @objc func goForwardTapped(_ sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @objc func reloadTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
    
    @objc func stopTapped(_ sender: UIBarButtonItem) {
        webView.stopLoading()
        updateToolbarItems()
    }
    
    @objc func actionButtonTapped(_ sender: AnyObject) {
        guard let url = webView.url else {
            return
        }
        
        let activities: NSArray = [XYSafariWebActivity(), XYChromeWebActivity()]
        if url.absoluteString.hasPrefix("file:///") {
            let dc: UIDocumentInteractionController = UIDocumentInteractionController(url: url)
            dc.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        } else {
            let activityController: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: activities as? [UIActivity])
            
            if floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                let ctrl: UIPopoverPresentationController = activityController.popoverPresentationController!
                ctrl.sourceView = view
                ctrl.barButtonItem = sender as? UIBarButtonItem
            }
            
            present(activityController, animated: true, completion: nil)
        }
    }
    
    @objc func doneButtonTapped() {
        closing = true
        UINavigationBar.appearance().barStyle = storedStatusColor!
        self.dismiss(animated: true, completion: nil)
    }
    
    class func bundledImage(named: String) -> UIImage? {
        let image = UIImage(named: named)
        if image == nil {
            return UIImage(named: named, in: Bundle(for: XYWebBrowserController.classForCoder()), compatibleWith: nil)
        }
        return image
    }
}


extension XYWebBrowserController: WKUIDelegate {
    // Add any desired WKUIDelegate methods here: https://developer.apple.com/reference/webkit/wkuidelegate
    
}

extension XYWebBrowserController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.delegate?.didStartLoading()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.didFinishLoading(success: true)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        webView.evaluateJavaScript("document.title", completionHandler: {(response, error) in
            self.navBarTitle.text = response as! String?
            self.navBarTitle.sizeToFit()
            self.updateToolbarItems()
        })
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFinishLoading(success: false)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        updateToolbarItems()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let url = navigationAction.request.url
        
        let hostAddress = navigationAction.request.url?.host
        
        if (navigationAction.targetFrame == nil) {
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.openURL(url!)
            }
        }
        
        // To connnect app store
        if hostAddress == "itunes.apple.com" {
            if UIApplication.shared.canOpenURL(navigationAction.request.url!) {
                UIApplication.shared.openURL(navigationAction.request.url!)
                decisionHandler(.cancel)
                return
            }
        }
        
        let url_elements = url!.absoluteString.components(separatedBy: ":")
        
        switch url_elements[0] {
        case "tel":
            openCustomApp(urlScheme: "telprompt://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "sms":
            openCustomApp(urlScheme: "sms://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "mailto":
            openCustomApp(urlScheme: "mailto://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        default:
            //print("Default")
            break
        }
        
        decisionHandler(.allow)
        
    }
    
    func openCustomApp(urlScheme: String, additional_info:String){
        if let requestUrl: URL = URL(string:"\(urlScheme)"+"\(additional_info)") {
            let application:UIApplication = UIApplication.shared
            if application.canOpenURL(requestUrl) {
                application.openURL(requestUrl)
            }
        }
    }
}


extension XYWebBrowserController: UITextFieldDelegate {
    
    private func reset() {
        UIView.animate(withDuration: 0.3) {
            self.tilteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width-60, height: 30)
        }
    }
    
    private func makeTransform() {
        UIView.animate(withDuration: 0.3) {
            self.tilteView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        makeTransform()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        reset()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        view.endEditing(true)
        reset()
        if let text = textField.text {
            loadingRequest(address: text)
        }
        return true
    }
}
