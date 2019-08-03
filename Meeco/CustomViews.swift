//
//  CustomView.swift
//  Meeco
//
//  Created by Kyujin Cho on 24/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import WebKit
import PureLayout

class ReplyView: UIView, WKNavigationDelegate {
    let replyInfo: ReplyInfo
    
    var horizontalDivider: UIView!
    var nicknameLabel: UILabel!
    var timeLabel: UILabel!
    var replyWebView: WKWebView!
    var inReplyToLabel: UILabel!
    var shouldSetupConstraints = true
    
    var wvHeight: CGFloat = 0.0
    
    init(frame: CGRect, replyInfo: ReplyInfo) {
        self.replyInfo = replyInfo
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.replyInfo = ReplyInfo()
        super.init(coder: aDecoder)
        initSubViews()
    }
    
    func initSubViews() {
        horizontalDivider = UIView(frame: CGRect.zero)
        nicknameLabel = UILabel(frame: CGRect.zero)
        timeLabel = UILabel(frame: CGRect.zero)
        replyWebView = WKWebView(frame: CGRect.zero)
        inReplyToLabel = UILabel(frame: CGRect.zero)
        
        replyWebView.navigationDelegate = self
        
        horizontalDivider.backgroundColor = UIColor(hexString: "#F1F1F1")
        nicknameLabel.text = replyInfo.nickname
        timeLabel.text = replyInfo.time
        replyWebView.loadHTMLString(decorateHTML(replyInfo.rawHTML), baseURL: URL(string: "https://meeco.kr"))
        
        nicknameLabel.font = UIFont(name: "HelveticaNeue", size: UIFont.smallSystemFontSize)
        
        timeLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
        timeLabel.textColor = UIColor.lightGray
//        self.backgroundColor = UIColor(hex: 0xF7F9FC)
        
        self.addSubview(horizontalDivider)
        self.addSubview(nicknameLabel)
        self.addSubview(timeLabel)
        self.addSubview(replyWebView)
        if replyInfo.replyTo.count > 0 {
            inReplyToLabel.text = "\(replyInfo.replyTo) 에게"
            inReplyToLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
            inReplyToLabel.textColor = UIColor.lightGray
            self.addSubview(inReplyToLabel)
        }
    }
    
    
    override func updateConstraints() {
        if shouldSetupConstraints {
            let leftEdgesInset: CGFloat = replyInfo.replyTo.count > 0 ? 24.0 : 8.0
            let edgesInset: CGFloat = 8.0
            let hrInset: CGFloat = 4.0
            let hrHeight: CGFloat = 0.67
            
            horizontalDivider.autoSetDimension(.height, toSize: hrHeight)
            horizontalDivider.autoPinEdge(toSuperviewEdge: .top, withInset: hrInset)
            horizontalDivider.autoPinEdge(toSuperviewEdge: .left, withInset: hrInset)
            horizontalDivider.autoPinEdge(toSuperviewEdge: .right, withInset: hrInset)

            nicknameLabel.autoPinEdge(.top, to: ALEdge.bottom, of: horizontalDivider, withOffset: edgesInset)
            nicknameLabel.autoPinEdge(toSuperviewEdge: .left, withInset: leftEdgesInset)
            nicknameLabel.autoPinEdge(toSuperviewEdge: .right, withInset: edgesInset)

            if replyInfo.replyTo.count > 0 {
                inReplyToLabel.autoPinEdge(.top, to: ALEdge.bottom, of: nicknameLabel, withOffset: edgesInset / 2)
                inReplyToLabel.autoPinEdge(toSuperviewEdge: .left, withInset: leftEdgesInset)
                inReplyToLabel.autoPinEdge(toSuperviewEdge: .right, withInset: edgesInset)
                timeLabel.autoPinEdge(.top, to: ALEdge.bottom, of: inReplyToLabel, withOffset: edgesInset / 2)
            } else {
                timeLabel.autoPinEdge(.top, to: ALEdge.bottom, of: nicknameLabel, withOffset: edgesInset / 2)
                
            }
            
            timeLabel.autoPinEdge(toSuperviewEdge: .left, withInset: leftEdgesInset)
            timeLabel.autoPinEdge(toSuperviewEdge: .right, withInset: edgesInset)
            
            replyWebView.autoPinEdge(.top, to: ALEdge.bottom, of: timeLabel, withOffset: 0.0)
            replyWebView.autoPinEdge(toSuperviewEdge: .left, withInset: leftEdgesInset - 8.0)
            replyWebView.autoPinEdge(toSuperviewEdge: .right, withInset: edgesInset)
            replyWebView.autoPinEdge(toSuperviewEdge: .bottom, withInset: edgesInset)
            
            if wvHeight > 0 {
                replyWebView.autoSetDimension(.height, toSize: wvHeight)
            }
            
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    let h = height as! CGFloat
                    self.wvHeight = h
                    self.shouldSetupConstraints = true
                    self.updateConstraints()
                })
            }
            
        })
    }
    
}
