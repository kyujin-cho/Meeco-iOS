//
//  TodayViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 21/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import KeychainSwift
import Alamofire
import PromiseKit

class TodayViewController: UITableViewController {
    let switchSegue = "SwitchToArticleViewFromTodaySegue"
    let fetcher = Fetcher()

    var articles: [[TodayRowInfo]] = [
        [], [], [], []
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        let uid = keychain.get("uid")
        if uid != nil && uid?.count > 0 {
            let username = keychain.get("username") ?? ""
            let password = keychain.get("password") ?? ""
            
            fetcher.tryLogin(userName: username, password: password) { uid, error in
                    self.fetcher.fetchToday()
                        .done { response in
                            for i in 0...3 {
                                self.articles[i].removeAll()
                                response[i].forEach { self.articles[i].append($0) }
                            }
                            self.tableView.reloadData()
                        }
                }
            
            
        } else {
            fetcher.fetchToday()
                .done { response in
                    for i in 0...3 {
                        self.articles[i].removeAll()
                        response[i].forEach { self.articles[i].append($0) }
                    }
                    self.tableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return "IT 소식"
        case 1:
            return "미니기기 / 음향"
        case 2:
            return "자유게시판"
        default:
            return "HOT 게시글"
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return articles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainCustomCell", for: indexPath) as! MainCustomCell
        let targetRow = articles[indexPath.section][indexPath.row]
        cell.titleLabel.text = targetRow.title
        cell.replyCountLabel.text = "댓글 \(targetRow.replyCount)개"
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == switchSegue,
            let destination = segue.destination as? ArticleViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            destination.boardId = articles[indexPath.section][indexPath.row].boardId
            destination.articleId = articles[indexPath.section][indexPath.row].articleId
        }
    }
}

