//
//  MainCustomCell.swift
//  Meeco
//
//  Created by Kyujin Cho on 21/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import WebKit

class MainCustomCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet var replyCountLabel: UILabel!
}

class NormalArticleRowCell: UITableViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var viewCountLabel: UILabel!
    @IBOutlet var replyCountLabel: UILabel!
    @IBOutlet var titleLeftConstraint: NSLayoutConstraint!
}

class AccountInfoCell: UITableViewCell {
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var userIdLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
}
