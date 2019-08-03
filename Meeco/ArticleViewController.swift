//
//  ArticleViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 22/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import WebKit
import PureLayout

class ArticleViewController: UIViewController, WKNavigationDelegate {
    var boardId = ""
    var articleId = ""
    
    let fetcher = Fetcher()
    var replies: [ReplyInfo] = []
    
    var article = ArticleInfo()
    
    var replyText = ""
    
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var viewCountLabel: UILabel!
    @IBOutlet var articleWebKit: WKWebView!
    @IBOutlet var replyCountLabel: UILabel!
    @IBOutlet var replySubView: UIView!
    
    @IBOutlet var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var titleLeftConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.articleWebKit.scrollView.isScrollEnabled = false
        self.articleWebKit.navigationDelegate = self
        
        loadArticle()
        
        let writeIcon = UIImage.init(imageLiteralResourceName: "write_18pt")
        let replyBtn = UIBarButtonItem(image: writeIcon, style: .plain, target: self, action: #selector(loadWriteReply(sender:)))

        self.navigationItem.rightBarButtonItem = replyBtn

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        super.viewWillDisappear(animated)
    }
    
    @objc func loadWriteReply(sender: Any) {
        let writeIcon = UIImage.init(imageLiteralResourceName: "write_18pt")
        let alert = UIAlertController(style: .alert, title: "TextField")
        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Your reply"
            textField.left(image: writeIcon, color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = nil
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.isSecureTextEntry = true
            textField.returnKeyType = .done
            textField.action { textField in
                self.replyText = textField.text ?? ""
            }
        }
        alert.addOneTextField(configuration: config)
        alert.addAction(title: "Cancel", style: .cancel)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (alert) in
            
        })
        alert.show()
    }
    
    func loadArticle() {
        fetcher.fetchArticle(boardId: boardId, articleId: articleId)
            .done { article in
                let edgesInset: CGFloat = 8.0

                self.titleLabel.text = article.title
                self.categoryLabel.text = article.category
                if article.categoryColor.count > 0 {
                    self.categoryLabel.textColor = UIColor(hexString: article.categoryColor)
                }
                if article.category.count == 0 {
                    self.titleLeftConstraint.constant = 0.0 as CGFloat
                }
                self.nicknameLabel.text = article.nickname
                self.timeLabel.text = article.time
                self.viewCountLabel.text = "조회수 \(article.viewCount)"
                self.replyCountLabel.text = "댓글 \(article.replies.count)개"
                
                self.articleWebKit.loadHTMLString(decorateHTML(article.rawHTML), baseURL: URL(string: "https://meeco.kr"))
                
                self.replySubView.subviews.forEach({ $0.removeFromSuperview() }) // this gets things done
                self.replies.removeAll()
                if article.replies.count > 0 {
                    let firstView = ReplyView(frame: CGRect.zero, replyInfo: article.replies[0])
                    self.replySubView.addSubview(firstView)
                    
                    firstView.autoPinEdge(toSuperviewEdge: .top)
                    firstView.autoPinEdge(toSuperviewEdge: .left)
                    firstView.autoPinEdge(toSuperviewEdge: .right)
                    
                    var lastView = firstView
                    if article.replies.count > 1 {
                        for reply in article.replies.suffix(from: 1) {
                            let otherView = ReplyView(frame: CGRect.zero, replyInfo: reply)
                            self.replySubView.addSubview(otherView)
                            
                            otherView.autoPinEdge(.top, to: ALEdge.bottom, of: lastView, withOffset: edgesInset)
                            otherView.autoPinEdge(toSuperviewEdge: .left)
                            otherView.autoPinEdge(toSuperviewEdge: .right)
                            lastView = otherView
                        }
                    }
                    lastView.autoPinEdge(toSuperviewEdge: .bottom)
                }
                
                
                
                for reply in article.replies {
                    self.replies.append(reply)
                    
                }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    let h = height as! CGFloat
                    self.webViewHeightConstraint.constant = h
                })
            }

        })
    }
}
