//
//  ArticleWriteViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 24/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import PureLayout
import RichEditorView
import WebKit

protocol NewArticleDelegate {
    func newArticlePosted(srl: String)
}

class ArticleWriteViewController: UIViewController, UIScrollViewDelegate {
    var delegate: NewArticleDelegate?
    
    var boardId = ""
    var articleId = ""
    var categories: [CategoryInfo] = []
    var categoryColors: [String] = []
    var selectedCategory = 0
    var contentTitle = ""
    var contentHTML = ""
    var targetSrl = ""
    
    var csrfToken = ""
    var editorSequence = ""
    var webView: WKWebView?
        
    let viewportScriptString = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); meta.setAttribute('initial-scale', '1.0'); meta.setAttribute('maximum-scale', '1.0'); meta.setAttribute('minimum-scale', '1.0'); meta.setAttribute('user-scalable', 'no'); document.getElementsByTagName('head')[0].appendChild(meta);"
    let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"
 
    var categoryBtn: UIBarButtonItem?
    
    let fetcher = Fetcher()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "새 글"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        let writeBtn = UIBarButtonItem(title: "작성", style: .plain, target: self, action: #selector(doWrite(sender:)))
        if self.categories.count > 0 {
            
            categoryBtn = UIBarButtonItem(title: categories[0].name, style: .plain, target: self, action: #selector(showCategoryToggle(sender:)))
            categoryBtn?.tintColor = UIColor(hexString: categories[0].color)
            self.navigationItem.rightBarButtonItems = [writeBtn, categoryBtn!]
        } else {
            self.navigationItem.rightBarButtonItem = writeBtn
        }
        
        loadWebView()
    }
    
    @objc func showCategoryToggle(sender: Any) {
        let alert = UIAlertController(style: .actionSheet, title: "카테고리 선택", message: nil)
        
        let pickerViewValues: [[String]] = [categories.map { $0.name }]
        let pickerViewSelectedValue: PickerViewViewController.Index = (column: 0, row: selectedCategory)
        
        alert.addPickerView(values: pickerViewValues, initialSelection: pickerViewSelectedValue) { vc, picker, index, values in
            DispatchQueue.main.async {
                self.selectedCategory = index.row
                self.categoryBtn?.title = self.categories[self.selectedCategory].name
                self.categoryBtn?.tintColor = UIColor(hexString: self.categories[self.selectedCategory].color)
            }
        }
        alert.addAction(title: "Done", style: .cancel)
        alert.show()
    }
    
    @objc func doWrite(sender: Any) {
        let finalHTML = contentHTML + "\n<p>MeecoApp@iOS</p>"
        fetcher.writeArticle(boardId: boardId, targetSrl: targetSrl, title: contentTitle, articleHtml: finalHTML, csrfToken: csrfToken)
            .done { srl in
                self.dismiss(animated: true)
                self.delegate?.newArticlePosted(srl: srl)
            }.catch { error in
                print(error)
        }
    }
    
    func loadWebView() {
        // 1 - Make user scripts for injection
        let viewportScript = WKUserScript(source: viewportScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        getArticleWritetRequiredData {
            // 2 - Initialize a user content controller
            // From docs: "provides a way for JavaScript to post messages and inject user scripts to a web view."
            let controller = WKUserContentController()
            
            controller.add(self, name: "article")
            
            // 3 - Add scripts
            controller.addUserScript(viewportScript)
            controller.addUserScript(disableCalloutScript)
            
            // 4 - Initialize a configuration and set controller
            let config = WKWebViewConfiguration()
            config.userContentController = controller
            
            let webView = WKWebView(frame: CGRect.zero, configuration: config)
            
            self.view.addSubview(webView)
            
            webView.autoPinEdge(toSuperviewEdge: .top, withInset: 0.0)
            webView.autoPinEdge(toSuperviewEdge: .left, withInset: 0.0)
            webView.autoPinEdge(toSuperviewEdge: .right, withInset: 0.0)
            webView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0.0)
            
            // 6 - Webview options
            webView.scrollView.isScrollEnabled = true               // Make sure our view is interactable
            webView.scrollView.bounces = false                    // Things like this should be handled in web code
            webView.allowsBackForwardNavigationGestures = false   // Disable swiping to navigate
            webView.contentMode = .scaleToFill // Scale the page to fill the web view
            webView.scrollView.delegate = self
            
            
            let url = Bundle.main.url(forResource: "editor", withExtension: "html", subdirectory: "editor")!
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
            
            self.webView = webView
        }
    }
    
    func getArticleWritetRequiredData(f: @escaping (() -> Void)) {
        fetcher.imageUploadRequiredData(boardId)
            .done { body in
                self.editorSequence = body["editorSequence"]!
                self.csrfToken = body["csrfToken"]!
                f()
        }
    }
    
    func uploadImage(imageAsBase64: String, id: String) {
//        fileName: String, imageDataAsBase64: String, boardId: String, targetSrl: String, editorSequence: String, csrfToken: String
        fetcher.imageUpload(fileName: id, imageDataAsBase64: imageAsBase64, boardId: boardId, targetSrl: targetSrl, editorSequence: editorSequence, csrfToken: csrfToken)
            .done { body in
                let url = body["url"]!
                if let wv = self.webView {
                    wv.evaluateJavaScript("window.onMessageReceive('\(id)', null, '\(url)')", completionHandler: nil)
                }
                self.targetSrl = body["targetSrl"]!
            }.catch { error in
                if let wv = self.webView {
                    wv.evaluateJavaScript("window.onMessageReceive('\(id)', 'Server rejected upload', null)", completionHandler: nil)
                }
        }
    }
 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        super.viewWillDisappear(animated)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}

extension ArticleWriteViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let messageBody = message.body as? [String: Any] {
            switch messageBody["event"] as? String {
            case "TitleChanged":
                self.contentTitle = messageBody["value"] as? String ?? ""
                break
            case "ContentChanged":
                self.contentHTML = messageBody["value"] as? String ?? ""
                break
            case "targetSrlChanged":
                self.targetSrl = messageBody["value"] as? String ?? ""
            case "postImage":
                let file = messageBody["file"] as! String
                let id = messageBody["id"] as! String
                self.uploadImage(imageAsBase64: file, id: id)
            default:
                break
            }
        }
    }
}
