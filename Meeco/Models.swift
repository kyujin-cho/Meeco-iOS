class Pair<P1, P2> {
    let l: P1
    let r: P2

    public init(l: P1, r: P2) {
        self.l = l
        self.r = r
    } 
}

class NormalRowInfo {
    let boardId: String
    let boardName: String
    let articleId: String
    let category: String
    let categoryColor: String
    let categories: Array<CategoryInfo>
    let title: String
    let nickname: String
    let time: String
    let viewCount: Int
    let replyCount: Int
    let hasImage: Bool
    let isSecret: Bool

    public init(boardId: String, boardName: String, articleId: String, category: String, categoryColor: String, categories: Array<CategoryInfo>, title: String, nickname: String, time: String, viewCount: Int, replyCount: Int, hasImage: Bool, isSecret: Bool) {
        self.boardId = boardId
        self.boardName = boardName
        self.articleId = articleId
        self.category = category
        self.categoryColor = categoryColor
        self.categories = categories
        self.title = title
        self.nickname = nickname
        self.time = time
        self.viewCount = viewCount
        self.replyCount = replyCount
        self.hasImage = hasImage
        self.isSecret = isSecret
    }
}

class TodayRowInfo {
    
    let boardId: String
    let articleId: String
    let title: String
    let replyCount: Int

    public init(boardId: String, articleId: String, title: String, replyCount: Int) {
        self.boardId = boardId
        self.articleId = articleId
        self.title = title
        self.replyCount = replyCount
    }
}

class ArticleInfo {
    
    var boardId: String = ""
    var articleId: String = ""
    var boardName: String = ""
    var category: String = ""
    var categoryColor: String = ""
    var title: String = ""
    var nickname: String = ""
    var userId: String = ""
    var time: String = ""
    var viewCount: Int = 0
    var replyCount: Int = 0
    var profileImageUrl: String = ""
    var likes: Int = 0
    var signature: String = ""
    var rawHTML: String = ""
    var informationName: String = ""
    var informationValue: String = ""
    var replies: Array<ReplyInfo> = []

    public init() {
    }

    public init(boardId: String, articleId: String, boardName: String, category: String, categoryColor: String, title: String, nickname: String, userId: String, time: String, viewCount: Int, replyCount: Int, profileImageUrl: String, likes: Int, signature: String, rawHTML: String, informationName: String, informationValue: String, replies: Array<ReplyInfo>) {
        self.boardId = boardId
        self.articleId = articleId
        self.boardName = boardName
        self.category = category
        self.categoryColor = categoryColor
        self.title = title
        self.nickname = nickname
        self.userId = userId
        self.time = time
        self.viewCount = viewCount
        self.replyCount = replyCount
        self.profileImageUrl = profileImageUrl
        self.likes = likes
        self.signature = signature
        self.rawHTML = rawHTML
        self.informationName = informationName
        self.informationValue = informationValue
        self.replies = replies
    }
    
}

class ReplyInfo {
    let selected = false
    
    var replyId: String = ""
    var boardId: String = ""
    var isWriter: Bool = false
    var articleId: String = ""
    var profileImageUrl: String = ""
    var nickname: String = ""
    var userId: String = ""
    var time: String = ""
    var replyContent: String = ""
    var likes: Int = 0
    var replyTo: String = ""
    var rawHTML: String = ""
    
    public init() {
        
    }

    public init(replyId: String, boardId: String, isWriter: Bool, articleId: String, profileImageUrl: String, nickname: String, userId: String, time: String, replyContent: String, likes: Int, replyTo: String, rawHTML: String) {
        self.replyId = replyId
        self.boardId = boardId
        self.isWriter = isWriter
        self.articleId = articleId
        self.profileImageUrl = profileImageUrl
        self.nickname = nickname
        self.userId = userId
        self.time = time
        self.replyContent = replyContent
        self.likes = likes
        self.replyTo = replyTo
        self.rawHTML = rawHTML
    }
    
}

class UserInfo {
    
    let userName: String
    let nickName: String
    let email: String
    let profileImageUrl: String

    public init(userName: String, nickName: String, email: String, profileImageUrl: String) {
        self.userName = userName
        self.nickName = nickName
        self.email = email
        self.profileImageUrl = profileImageUrl
    }
    
}

class Cookie {
    let value: String
    let options: String

    public init(value: String, options: String) {
        self.value = value
        self.options = options
    }
}

class POSTResponse {
    var message: String = ""
    var error: Int = 0
    
    public init() {
        
    }

    public init(message: String, error: Int) {
        self.message = message
        self.error = error
    }
}

class CategoryInfo {
    let id: String
    let name: String
    let color: String


    public init(id: String, name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}
