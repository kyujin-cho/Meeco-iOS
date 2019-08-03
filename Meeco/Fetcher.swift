//
//  Fetcher.swift
//  Meeco
//
//  Created by Kyujin Cho on 21/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import Alamofire
import PromiseKit
import SwiftSoup

import UIKit

extension String
{
    func trim() -> String
    {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}

class RequestError : Error {
    var localizedTitle: String
    var localizedDescription: String = ""
    
    init (_ localizedTitle: String) {
        self.localizedTitle = localizedTitle
        
        
    }
    
    init (_ localizedTitle: String, localizedDescription: String) {
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        
    }
}

class Fetcher {
    let sess: SessionManager
    init() {
        let configuration = URLSessionConfiguration.default
        var defaultHeaders = Dictionary<String, String>()
        defaultHeaders["User-Agent"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.0 Mobile/15E148 Safari/604.1"
        configuration.httpAdditionalHeaders = defaultHeaders
        
        sess = SessionManager(configuration: configuration)
    }
    
    func asyncGet(_ url: String, method: HTTPMethod) -> Promise<DataResponse<String>> {
        return Promise { seal in
            sess.request(url, method: method).responseString { response in
                seal.fulfill(response)
            }
        }
    }
    
    func asyncPost(_ url: String, parameters: [String : Any]?) -> Promise<DataResponse<String>> {
        return Promise { seal in
            sess.request(url, method: .post, parameters: parameters).responseString { response in
                seal.fulfill(response)
            }
        }
    }
    
    func asyncPostWithHeader(_ url: String, parameters: [String: Any]?, headers: Dictionary<String, String>) -> Promise<DataResponse<Any>> {
        return Promise { seal in
            sess.request(url, method: .post, parameters: parameters, headers: headers).responseJSON { response in
                seal.fulfill(response)
            }
        }
    }
    
    func fetchNormal(boardId: String, categoryName: String, pageNum: Int) -> Promise<Array<NormalRowInfo>> {
        var articles = Array<NormalRowInfo>()
        return Promise { seal in
            asyncGet("https://meeco.kr/index.php?mid=\(boardId)&page=\(pageNum)&category=\(categoryName)", method: HTTPMethod.get)
                .done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        if try doc.select("div.list_document div.ldd").size() == 0 {
                            seal.fulfill(articles)
                            return
                        }
                        
                        let hasCategory = try doc.select(".bt_ctg").size() > 0
                        var categories = Array<CategoryInfo>()
                        
                        if (hasCategory) {
                            categories = try doc.select("div.list_category > ul > li")
                                .filter { x in
                                    try x.select("a").first()?.attr("href").split(separator: "/").contains("category") ?? false
                                }
                                .map { x in
                                    let styleStr = try x.select("span").attr("style").split(separator: ":")
                                    return
                                        CategoryInfo(
                                        id: String(try x.select("a").first()?.attr("href").split(separator: "/").last ?? ""),
                                        name: try x.text().trim(),
                                        color: styleStr.count > 1 ? String(try x.select("span").attr("style").split(separator: ":")[1]) : ""
                                    )
                            }
                            categories.insert(CategoryInfo(id: "", name: "전체", color: ""), at: 0)
                        }
                        
                        
                        for item in try doc.select("div.list_document div.ldd li") {
                            if try item.select("a.list_link").size() == 0 {
                                continue
                            }
                            
                            var category = ""
                            var categoryColor = ""
                            let titleAnchor = try item.select("a.list_link")
                            let infoDiv = try item.select("div.list_info").first()?.children()
                            var replyCount = 0
                            var articleId = ""
                            
                            if hasCategory {
                                category = try (item.select("span.list_ctg").first()?.text() ?? "").trim()
                                let styleStr = try item.select("span.list_ctg").first()?.attr("style") ?? ""
                                if styleStr.count > 0 {
                                    categoryColor = String(styleStr.split(separator: "#")[1])
                                } else {
                                    categoryColor = "616BAF"
                                }
                            }
                            
                            if (try item.select("a.list_cmt").size() > 0) {
                                replyCount = Int(try item.select("a.list_cmt").first()?.text() ?? "0") ?? 0
                            }
                            
                            if (try titleAnchor.first()?.attr("href").range(of: "/\(boardId)/[0-9]+", options: .regularExpression)) != nil {
                                articleId = String(try titleAnchor.first()?.attr("href").split(separator: "/").last ?? "")
                            } else {
                                articleId = String(try titleAnchor.first()?.attr("href").split(separator: "=").last ?? "")
                            }
                            
                            articles.append(
                                NormalRowInfo(boardId: boardId,
                                              boardName: try doc.select("li.list_bt_board.active > a").text(),
                                              articleId: articleId,
                                              category: category,
                                              categoryColor: categoryColor,
                                              categories: categories,
                                              title: try titleAnchor.attr("title"),
                                              nickname: try infoDiv?.array()[0].text() ?? "",
                                              time: try infoDiv?.array()[1].text() ?? "",
                                              viewCount: try Int(infoDiv?.array()[2].text() ?? "0") ?? 0,
                                              replyCount: replyCount,
                                              hasImage: try doc.select("span.list_title > span.list_icon2.image").size() > 0,
                                              isSecret: try doc.select("span.list_title > span.list_icon2.secret").size() > 0 && (try infoDiv?.first()?.text()) == "******"
                                )
                            )
                        }
                        
                        seal.fulfill(articles)
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
                }.catch { error in
                    print(error)
                    seal.reject(error)
            }
        }
        
    }
    
    func fetchArticle(boardId: String, articleId: String) -> Promise<ArticleInfo> {
        return Promise { seal in
            let url = "https://meeco.kr/\(boardId)/\(articleId)"
            asyncGet(url, method: .get)
                .done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        print(htmlStr)
                        var isLoggedIn = try doc.getElementsByClass("xi-log-out").size() > 0
                        
                        var hasCategory = try doc.select(".bt_ctg").size() > 0
                        var infoList = try doc.select("div.atc_info > ul > li").array()
                        var category = ""
                        var categoryColor = ""
                        var innerHTML = try doc.select("div.atc_body > div.xe_content")
                        var replies = try doc.select("div.cmt_list > article.cmt_unit").array()
                        var informationName = ""
                        var informationValue = ""
                        var articleWriterId = ""
                        
                        if try doc.select("div.atc_ex table tbody").size() > 0 {
                            let row = try doc.select("div.atc_ex table tbody tr")
                            informationName = try row.select("th").first()?.text() ?? ""
                            
                            if try doc.select("td.a").size() > 0 {
                                informationValue = try doc.select("td.a").first()?.attr("href") ?? ""
                            } else {
                                informationName = try doc.select("td").first()?.text() ?? ""
                            }
                        }
                        
                        if try doc.select("div.cmt_list").size() > 0 {
                            for row in try doc.select("div.cmt_list img").array() {
                                if try row.attr("src").starts(with: "//") {
                                    try row.attr("src", "https:" + row.attr("src"))
                                }
                            }
                        }
                        
                        for row in try innerHTML.select("img").array() {
                            if try row.attr("src").starts(with: "//") {
                                try row.attr("src", "https:" + row.attr("src"))
                            }
                        }
                        
                        if hasCategory {
                            category = try doc.select("span.atc_ctg").text().trim()
                            categoryColor = String(try doc.select("span.atc_ctg > span").attr("style").split(separator: "#")[1])
                        }
                        
                        if try doc.select("div.atc_info > span.nickname > a > span").size() > 0 {
                            articleWriterId = (try doc.select("div.atc_info > span.nickname > a > span").first()?.className() ?? "").replacingOccurrences(of: "member_", with: "")
                        }
                        
                        let replyList = try replies.map { item -> ReplyInfo in
                            for anchor in try item.select("div.xe_content a").array() {
                                if try anchor.attr("href").starts(with: "https://meeco.kr/index.php?mid=sticker&sticker_srl=") {
                                    var css = Dictionary<String, String>()
                                    for cssItem in try anchor.attr("style").split(separator: ";") {
                                        let x = String(cssItem).replacingOccurrences(of: "://", with: "$//")
                                        var s = x.split(separator: ":")
                                        if s.count < 2 {
                                            continue
                                        }
                                        css[String(s[0]).trim()] = String(s[1]).trim().replacingOccurrences(of: "$//", with: "://")
                                    }
                                    
                                    if css.keys.count > 0 {
                                        let stickerUrl = css["background-image"]
                                        if let stickerUrl = stickerUrl {
                                            let start = stickerUrl.index(stickerUrl.startIndex, offsetBy: 4)
                                            let end = stickerUrl.index(stickerUrl.endIndex, offsetBy: -1)
                                            let range = start..<end
                                            
                                            try anchor.html("<img src=\"\(stickerUrl[range])\" style=\"width: 140px; height: 140px;\">")
                                        }
                                    }
                                }
                            }
                            
                            return ReplyInfo(
                                replyId: item.id().replacingOccurrences(of: "comment_", with: ""),
                                boardId: boardId,
                                isWriter: try item.select("div.pf_wrap > span.writer").size() > 0,
                                articleId: articleId,
                                profileImageUrl: try item.select("img.pf_img").size() > 0 ? try item.select("img.pf_img").first()?.attr("src") ?? "" : "",
                                nickname: try item.select("span.nickname").text().trim(),
                                userId: isLoggedIn ? try item.select("span.nickname").first()?.className().replacingOccurrences(of: "nickname member_", with: "") ?? "" : "",
                                time: try item.select("span.date").text(),
                                replyContent: try item.select("div.xe_content").html(),
                                likes: Int(try item.select("span.cmt_vote_up").text()) ?? 0,
                                replyTo: try item.select("div.cmt_to").size() > 0 ? try item.select("div.cmt_to").first()?.text() ?? "" : "",
                                rawHTML: try item.select("div.xe_content").html()
                            )
                        }
                        
                        seal.fulfill(ArticleInfo(
                            boardId: boardId,
                            articleId: articleId,
                            boardName: try doc.select("li.list_bt_board").text(),
                            category: category,
                            categoryColor: categoryColor,
                            title: try doc.select("header.atc_hd > h1 > a").text(),
                            nickname: isLoggedIn ? try doc.select("div.atc_info > span.nickname > a").first()?.text().trim() ?? "" : try doc.select("div.atc_info > span.nickname").text().trim(),
                            userId: articleWriterId,
                            time: try infoList[0].text(),
                            viewCount: Int(try infoList[1].text()) ?? 0,
                            replyCount: Int(try infoList[2].text()) ?? 0,
                            profileImageUrl: try doc.select("div.atc_info span.pf img").size() > 0 ? try doc.select("div.atc_info span.pf img").attr("src") : "",
                            likes: try doc.select("button.bt_atc_vote").size() > 0
                                ? Int(try doc.select("button.bt_atc_vote span.num").text()) ?? 0
                                : -1,
                            signature: try doc.select("div.atc_sign_body").size() > 0 ? try doc.select("div.atc_sign_body").text() : "",
                            rawHTML: try doc.select("div.atc_body > div.xe_content").html(),
                            informationName: informationName,
                            informationValue: informationValue,
                            replies: replyList
                        ))
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
            }
        }
    }
    
    func parseItemsFromFragment(_ fragment: Element) throws -> [TodayRowInfo] {
        return try fragment.select("li.has_date").array().map { item in
            let href = try item.select("a").attr("href").split(separator: "/")
            var replies = 0
            
            if try item.select("span.list_cmt").size() > 0 {
                let replyText = try item.select("span.list_cmt").text()
                replies = Int(replyText.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")) ?? 0
            }
            
            return TodayRowInfo(boardId: String(href[0]), articleId: String(href[1]), title: try item.select("span.list_title").text(), replyCount: replies)
        }
    }
    
    func fetchToday() -> Promise<[[TodayRowInfo]]> {
        return Promise { seal in
            asyncGet("https://meeco.kr/", method: .get)
                .done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        let fragments = try doc.select("div.xe-widget-wrapper[style=\"width: 100%; float: left;\"]").array()
                        
                        seal.fulfill([
                            try self.parseItemsFromFragment(fragments[0]),
                            try self.parseItemsFromFragment(fragments[1]),
                            try self.parseItemsFromFragment(fragments[2]),
                            try self.parseItemsFromFragment(fragments[5])
                        ])
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
            }
        }
    }
    
    func tryLogin(userName: String, password: String, completion: @escaping (String, Error?) -> ()) {
        let commonError = NSError(domain: "", code: 404, userInfo: nil)
            asyncGet("https://meeco.kr/index.php?mid=mini&act=dispMemberLoginForm", method: .get)
                .map { response -> [String : Any] in
                if response.result.value == nil {
                    completion("", RequestError("Error while parsing CSRF token"))
                    throw RequestError("Error while parsing CSRF token")
                }
                let doc = try! SwiftSoup.parse(response.result.value ?? "")
                
                let csrf = try doc.select("meta[name=\"csrf-token\"]").attr("content")
                let postData: [String: String] = [
                    "error_return_url": "/index.php?mid=mini&act=dispMemberLoginForm",
                    "mid": "mini",
                    "vid": "",
                    "module": "member",
                    "redirect_url": "/mini",
                    "act": "procMemberLogin",
                    "xe_validator_id": "modules/member/m.skin/default/login_form/1",
                    "user_id": userName,
                    "password": password,
                    "_rx_csrf_token": csrf,
                    "keep_signed": "N"
                ]
                
                return postData
                }.then { postData -> Promise<DataResponse<String>> in
                    return self.asyncPost("https://meeco.kr", parameters: postData)
                }.map { response -> Int in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        return try doc.select("div.message.error").size() > 0 ? -1 : 0
                    }
                    
                    return -1
                }.then { errorCode -> Promise<DataResponse<String>> in
                    if (errorCode != 0) {
                        completion("", RequestError("Encountered non-zero error code for the response of login request"))
                        throw RequestError("Encountered non-zero error code for the response of login request")
                    }

                    return self.asyncGet("https://meeco.kr/", method: .get)
                }.done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        let uidField = try doc.select("div.mb_area.logged > a").first()?.attr("href") ?? ""
                        var uid = ""
                        let regex = try? NSRegularExpression(pattern: "member_srl=([0-9]+)", options: .caseInsensitive)
                        print("UID Field: \(uidField)")
                        if let match = regex?.firstMatch(in: uidField, options: [], range: NSRange(location: 0, length: uidField.utf16.count)), let uidRange = Range(match.range(at: 1), in: uidField) {
                            uid = String(uidField[uidRange])
                            print("UID: \(uid)")
                            completion(uid, nil)
                        } else {
                            completion("", RequestError("Error while parsing UserID"))
                            throw RequestError("Error while parsing UserID")

                        }
                    } else {
                        completion("", RequestError("Error while parsing UserID"))
                        throw RequestError("Error while parsing UserID")

                    }
            }
        
    }
    
    func fetchUserData(_ uid: String) -> Promise<[String]> {
        return Promise { seal in
            asyncGet("https://meeco.kr/index.php?mid=index&act=dispMemberInfo&member_srl=\(uid)", method: .get)
                .done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        let table = try doc.select("div.mb_table > table > tbody > tr").array()
                        seal.fulfill([
                            try table[0].select("td").text(),
                            try table[2].select("td").text(),
                            try table[1].select("td").text(),
                            try doc.select("div.mb_pf > span.pf > img").attr("src")
                        ])
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
            }
        }
    }
    
    func imageUploadRequiredData(_ boardId: String) -> Promise<[String: String]> {
        return Promise { seal in
            asyncGet("https://meeco.kr/index.php?mid=\(boardId)&act=dispBoardWrite", method: .get)
                .done { response in
                    if let htmlStr = response.result.value, let doc = try? SwiftSoup.parse(htmlStr) {
                        let regex = try? NSRegularExpression(pattern: "xe_editor_sequence: ([0-9]+),", options: .caseInsensitive)
                        
                        let csrfToken = try doc.select("meta[name=\"csrf-token\"]").attr("content")
                        if let match = regex?.firstMatch(in: htmlStr, options: [], range: NSRange(location: 0, length: htmlStr.utf16.count)), let seqRange = Range(match.range(at: 1), in: htmlStr) {
                            let editorSequence = String(htmlStr[seqRange])
                            seal.fulfill([
                                "editorSequence": editorSequence,
                                "csrfToken": csrfToken
                            ])
                        } else {
                            seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                        }
                        
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
            }
        }
    }
    
    func imageUpload(fileName: String, imageDataAsBase64: String, boardId: String, targetSrl: String, editorSequence: String, csrfToken: String) -> Promise<[String: String]> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                /* "Authorization": "your_access_token",  in case you need authorization header */
                "Content-type": "multipart/form-data",
                "X-CSRF-Token": csrfToken,
                "Host": "meeco.kr",
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0_1 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A402 Safari/604.1",
                "X-Requested-With": "XMLHttpRequest"
            ]
            let time = Int(NSDate().timeIntervalSince1970 * 1000)
            let rand = Float.random(in: 0..<1)
            let data = Data(base64Encoded: imageDataAsBase64, options: .ignoreUnknownCharacters)
            sess.upload(multipartFormData: { (multipart) in
                multipart.append(editorSequence.data(using: String.Encoding.utf8)!, withName: "editor_sequence")
                multipart.append(targetSrl.data(using: String.Encoding.utf8)!, withName: "upload_target_srl")
                multipart.append(boardId.data(using: String.Encoding.utf8)!, withName: "mid")
                multipart.append("procFileUpload".data(using: String.Encoding.utf8)!, withName: "act")
                multipart.append("T\(time).\(rand)".data(using: String.Encoding.utf8)!, withName: "nonce")
                
                multipart.append(data!, withName: "Filedata", fileName: "\(fileName).png", mimeType: "image/png")
            }, usingThreshold: UInt64.init(), to: "https://meeco.kr", method: .post, headers: headers) { (result) in
                switch result{
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        print("Succesfully uploaded")
                        if let result = response.result.value {
                            let json = result as! NSDictionary
                            if json["error"] as! Int == 0 {
                                let downloadUrl = json["download_url"] as! String
                                seal.fulfill([
                                    "targetSrl": String(json["upload_target_srl"] as! Int),
                                    "url": "https://img.meeco.kr\(downloadUrl)"
                                ])
                            } else {
                                seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                            }
                        } else {
                            seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                        }
                    }
                case .failure(let error):
                    print("Error in upload: \(error.localizedDescription)")
                    seal.reject(error)
                }
            }
        }
    }
    
    func writeArticle(boardId: String, targetSrl: String, title: String, articleHtml: String, csrfToken: String) -> Promise<String> {
        return Promise { seal in
            let body = [
                "_filter": "insert",
                "error_return_url": "/index.php?mid=$boardId&act=dispBoardWrite",
                "act": "procBoardInsertDocument",
                "mid": boardId,
                "content": articleHtml,
                "title": title,
                "comment_status": "ALLOW",
                "_rx_csrf_token": csrfToken,
                "use_ed:r": "Y",
                "use_html": "Y",
                "module": "board",
                "_rx_ajax_compat": "XMLRPC",
                "vid": "",
                "document_srl": targetSrl.count > 0 ? targetSrl : "0",
                "_saved_doc_message": "자동 저장된 글이 있습니다. 복구하시겠습니까? 글을 다 쓰신 후 저장하면 자동 저장 본은 사라집니다."
            ]
            
            let headers = [
                "Referer": "https://meeco.kr",
                "X-CSRF-Token": csrfToken,
                "X-Requested-With": "XMLHttpRequest"
            ]
            
            Alamofire.request("https://meeco.kr/", method: .post, parameters: body, headers: headers).responseJSON { response in
                if let result = response.result.value {
                    let json = result as! NSDictionary
                    if json["error"] as! Int == 0 {
                        seal.fulfill(String(json["document_srl"] as! Int))
                    } else {
                        seal.reject(NSError(domain: "", code: 404, userInfo: nil))
                    }
                }
            }
        }
    }
    
    func writeReply(boardId: String, articleId: String, replyId: String, editCommentId: String, replyContent: String, f: @escaping (() -> ())) throws {
        
        asyncGet("https://meeco.kr/\(boardId)/\(articleId)", method: .get)
            .map { response -> [String: String] in
                if let htmlStr = response.result.value, let obj = try? SwiftSoup.parse(htmlStr) {
                    let csrfToken = try obj.select("meta[name=\"csrf-token\"]").attr("content")
                    let replyContentAsHTML = replyContent.split(separator: "\n").map { (substring) -> String in
                        "<p>\(substring)</p>"
                    }.joined(separator: "\n")

                    var formData: [String: String] = [
                        "_filter": "insert_comment",
                        "error_return_url": "/\(boardId)/\(articleId)",
                        "mid": boardId,
                        "document_srl": articleId,
                        "comment_srl": editCommentId,
                        "_rx_csrf_token": csrfToken,
                        "use_editor": "Y",
                        "use_html": "Y",
                        "module": "board",
                        "act": "procBoardInsertComment",
                        "_rx_ajax_compat": "XMLRPC",
                        "vid": "",
                        "content": String(replyContentAsHTML)
                    ]
                    
                    if replyId.count > 0 {
                        formData["parent_srl"] = replyId
                    }
                    
                    return formData
                } else {
                    throw NSError(domain: "", code: 404, userInfo: nil)
                }
            }.then { body -> Promise<DataResponse<Any>> in
                let headers: [String: String] = [
                    "Referer": "https://meeco.kr",
                    "X-Requested-With": "XMLHttpRequst",
                    "X-CSRF-Token": body["_rx_csrf_token"] ?? ""
                ]
                return self.asyncPostWithHeader("https://meeco.kr/", parameters: body, headers: headers)
            }.done { response in
                if let result = response.result.value {
                    let json = result as! NSDictionary
                    if json["error"] as! Int == 0 {
                        f()
                    } else {
                        throw NSError(domain: "", code: 404, userInfo: nil)
                    }
                } else {
                    throw NSError(domain: "", code: 404, userInfo: nil)
                }
        }
    }
}
