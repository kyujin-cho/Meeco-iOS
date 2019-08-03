//
//  SettingsViewController.swift
//  Meeco
//
//  Created by Kyujin Cho on 24/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import UIKit
import KeychainSwift

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

class SettingsViewController: UITableViewController {
    var rows: [[Pair<String, String>]] = [
        [stringPair(l: "계정", r: "")]
    ]
    
    var username = ""
    var password = ""
    let fetcher = Fetcher()
    var userData = [
        "", "", "", ""
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        if let uid = keychain.get("uid") {
            if uid.count == 0 {
                return
            }
            
            updateLoginInfo(uid)
        } else {
            print("Not logged in")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : rows[section - 1].count - 1
    }
    
    override
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "내 계정" :  rows[section - 1][0].l
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountInfoCell", for: indexPath) as! AccountInfoCell
            if userData[0].count > 0 {
                cell.profileImageView.downloaded(from: userData[3])
                cell.userIdLabel.text = userData[0]
                cell.nicknameLabel.text = userData[1]
                cell.emailLabel.text = userData[2]
            } else {
                let meecoIcon = UIImage(imageLiteralResourceName: "MeecoIcon")
                cell.profileImageView.image = meecoIcon
                cell.nicknameLabel.text = "로그인 되지 않음"
                cell.userIdLabel.text = "여기를 터치하여 로그인하세요."
                cell.emailLabel.text = ""
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NormalSettingCell", for: indexPath)
            cell.textLabel!.text = rows[indexPath.section - 1][indexPath.row + 1].l
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            doLogin()
        } else {
            print(rows[indexPath.section-1][indexPath.row+1].r)
            switch rows[indexPath.section-1][indexPath.row+1].r {
            case "doLogout":
                doLogout()
                break
            default:
                break
            }
        }
    }
    
    func doLogin() {
        let alert = UIAlertController(style: .actionSheet)
        let user = UIImage(imageLiteralResourceName: "account_circle_18pt")
        let lock = UIImage(imageLiteralResourceName: "lock_18pt")
        let configOne: TextField.Config = { textField in
            textField.left(image: user, color: .black)
            textField.leftViewPadding = 16
            textField.leftTextPadding = 12
            textField.becomeFirstResponder()
            textField.backgroundColor = nil
            textField.textColor = .black
            textField.placeholder = "Username"
            textField.clearButtonMode = .whileEditing
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.action { textField in
                self.username = textField.text ?? ""
            }
        }
        
        let configTwo: TextField.Config = { textField in
            textField.textColor = .black
            textField.placeholder = "Password"
            textField.left(image: lock, color: .black)
            textField.leftViewPadding = 16
            textField.leftTextPadding = 12
            //                textField.borderWidth = 1
            //                textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = nil
            textField.clearsOnBeginEditing = true
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.isSecureTextEntry = true
            textField.returnKeyType = .done
            textField.action { textField in
                self.password = textField.text ?? ""
            }
        }
        // vInset - is top and bottom margin of two textFields
        
        alert.addTwoTextFields(height: 58, hInset: 0, vInset: 0, textFieldOne: configOne, textFieldTwo: configTwo)
        alert.addAction(UIAlertAction(title: "Log In", style: .default, handler: { (action) in
            
            self.fetcher.tryLogin(userName: self.username, password: self.password) { uid, error in
                
                if error != nil {
                    print("ERROR!!")
                    let alert = UIAlertController(style: .alert, title: "로그인 실패", message: "로그인에 실패했습니다.")
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                    alert.show()
                } else {
                    DispatchQueue.main.async {
                        let keychain = KeychainSwift()
                        keychain.synchronizable = true
                        keychain.set(self.username, forKey: "username")
                        keychain.set(self.password, forKey: "password")
                        keychain.set(uid, forKey: "uid")
                        self.updateLoginInfo(uid)
                    }
                }
                
            }
        }))
        alert.show()
    }
    
    func updateLoginInfo(_ uid: String) {
        fetcher.fetchUserData(uid)
            .done { userData in
                //                    public userName: string
                //                    public nickName: string
                //                    public email: string
                //                    public profileImageUrl: string
                self.rows[0].append(stringPair(l: "로그아웃", r: "doLogout"))
                for i in 0...3 {
                    self.userData[i] = userData[i]
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
        }
    }
    
    func doLogout() {
        let storage = HTTPCookieStorage.shared
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        for cookie in storage.cookies! {
            storage.deleteCookie(cookie)
        }
        self.rows[0].removeAll { p in
            p.r == "doLogout"
        }
        for i in 0...3 {
            self.userData[i] = ""
        }
        keychain.delete("uid")
        keychain.delete("username")
        keychain.delete("password")
        self.tableView.reloadData()
    }
}
