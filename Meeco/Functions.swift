//
//  Functions.swift
//  Meeco
//
//  Created by Kyujin Cho on 22/03/2019.
//  Copyright © 2019 Kyujin Cho. All rights reserved.
//

import Foundation

func decorateHTML(_ html: String) -> String {
    return decorateHTML(html, backgroundColor: "white")
}

func decorateHTML(_ html: String, backgroundColor: String) -> String {
    return """
    <html>
        <head>
            <meta name="viewport"  content="width=device-width, initial-scale=1, maximum-scale=1"/>
    <style> * { background-color: \(backgroundColor); font-family: -apple-system; } body { width: 96%; margin-bottom: -30px; } img { max-width: 100%; width: auto; height: auto; } iframe { max-width: 100%; } video { max-width: 100%; } </style>
        </head>
        <body>
            \(html)
        </body>
    </html>
    """
}

func decorateArticleHTML(_ article: ArticleInfo) -> String {
    return """
    <html>
        <head>
            <meta name="viewport"  content="width=device-width, initial-scale=1, maximum-scale=1"/>
            <style> body { font-family: -apple-system; } img { max-width: 100%; width: auth; height: auto; } iframe { max-width: 100%; } video { max-width: 100% } </style>
        </head>
        <body>
            <h2>\(article.title)</h2>
            <hr />
            \(article.rawHTML)
        </body>
    </html>
    """
}

func stringPair(l: String, r: String) -> Pair<String, String> {
    return Pair<String, String>(l: l, r: r)
}
