//
//  NormalArticleListViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 21/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import KeychainSwift


extension UIColor {
    convenience init(hexString:String) {
        let hexString = hexString.trim()
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

class NormalArticleListViewController: UITableViewController {
    var boardId = ""
    var boardName = ""
    
    let fetcher = Fetcher()
    let switchSegue = "SwitchToArticleViewSegue"
    
    var articles: [NormalRowInfo] = []
    var page = 1
    var isFetchingData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = boardName
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        fetcher.fetchNormal(boardId: boardId, categoryName: "", pageNum: 1)
            .done { response in
                for row in response {
                    self.articles.append(row)
                }
                self.tableView.reloadData()
        }
            .catch { error in
                print(error)
        }
        
        let refreshControl = UIRefreshControl()
        let title = "Pull to refresh"
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.addTarget(self, action: #selector(refreshData(sender: )), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        
        let searchIcon = UIImage.init(imageLiteralResourceName: "search_18pt")
        let searchBtn = UIBarButtonItem(image: searchIcon, style: .plain, target: self, action: #selector(searchArticle(sender:)))

        if keychain.get("uid") != nil {
            let writeIcon = UIImage.init(imageLiteralResourceName: "write_18pt")
            let writeBtn = UIBarButtonItem(image: writeIcon, style: .plain, target: self, action: #selector(writeArticle(sender:)))
            self.navigationItem.rightBarButtonItems = [writeBtn, searchBtn]
        } else {
            self.navigationItem.rightBarButtonItem = searchBtn
            
        }
        
        
    }
    
    
    @objc func writeArticle(sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ArticleWriteViewController") as! ArticleWriteViewController
        vc.boardId = boardId
        vc.delegate = self
        if articles[0].categories.count > 0 {
            vc.categories = Array<CategoryInfo>(articles[0].categories.suffix(from: 1))
        } else {
            vc.categories = articles[0].categories
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func searchArticle(sender: Any) {
        
    }
    
    @objc func refreshData(sender: Any) {
        page = 1
        fetcher.fetchNormal(boardId: boardId, categoryName: "", pageNum: 1)
            .done { response in
                self.articles.removeAll()
                for row in response {
                    self.articles.append(row)
                }
                self.tableView.reloadData()
                
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
            .catch { error in
                print(error)
        }
    }
    
    func getMoreData() {
        page += 1
        fetcher.fetchNormal(boardId: boardId, categoryName: "", pageNum: page)
            .done { response in
                for row in response {
                    self.articles.append(row)
                }
                self.tableView.reloadData()
                self.isFetchingData = false
            }
            .catch { error in
                print(error)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y  + 1) >= (scrollView.contentSize.height - scrollView.frame.size.height) && articles.count > 0 && !isFetchingData {
            isFetchingData = true
            getMoreData()
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NormalArticleRowCell", for: indexPath) as! NormalArticleRowCell
        let targetRow = articles[indexPath.row]
        
        cell.titleLabel.text = targetRow.title
        cell.categoryLabel.text = targetRow.category
        if targetRow.categoryColor.count > 0 {
            cell.categoryLabel.textColor = UIColor(hexString: targetRow.categoryColor)
        }
        if targetRow.category.count == 0 {
            cell.titleLeftConstraint.constant = 0.0 as CGFloat
        }
        cell.nicknameLabel.text = targetRow.nickname
        cell.timeLabel.text = targetRow.time
        cell.viewCountLabel.text = "조회수 \(targetRow.viewCount)"
        cell.replyCountLabel.text = "댓글 \(targetRow.replyCount)"
        
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == switchSegue,
            let destination = segue.destination as? ArticleViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            destination.boardId = boardId
            destination.articleId = articles[indexPath.row].articleId
        }
    }
}

extension NormalArticleListViewController: NewArticleDelegate {
    func newArticlePosted(srl: String) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ArticleViewController") as! ArticleViewController
        vc.boardId = boardId
        vc.articleId = srl
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
