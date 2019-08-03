//
//  BoardsViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 21/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit

func makePair(l: String, r: String) -> Pair<String, String> {
    return Pair<String, String>(l: l, r: r)
}

class BoardsViewController: UITableViewController {
    let rows = [
        [makePair(l: "커뮤니티", r: ""), makePair(l: "IT 소식", r: "news"), makePair(l: "미니기기 / 음향", r: "mini"), makePair(l: "자유 게시판", r: "free"), makePair(l: "갤러리", r: "gallery"), makePair(l: "장터 게시판", r: "market")],
        [makePair(l: "파일럿 게시판", r: ""), makePair(l: "유머 게시판", r: "humor"), makePair(l: "영화 게시판", r: "movie")],
        [makePair(l: "운영 참여", r: ""), makePair(l: "신고 건의", r: "contact"), makePair(l: "공지사항", r: "notice")]
    ]
    @IBOutlet var boardListTableView: UITableView!
    
    let showNormalSegueIdentifier = "ShowNormalArticleSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count - 1
    }
    
    override
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return rows[section][0].l
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardListCell", for: indexPath)
        cell.textLabel!.text = rows[indexPath.section][indexPath.row + 1].l
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showNormalSegueIdentifier,
            let destination = segue.destination as? NormalArticleListViewController,
            let indexPath = boardListTableView.indexPathForSelectedRow {
                let selectedRow = rows[indexPath.section][indexPath.row + 1]
                destination.boardId = selectedRow.r
                destination.boardName = selectedRow.l
        }
    }
}
