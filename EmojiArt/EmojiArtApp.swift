//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    // 创建一个用于演示的 document
    let document = EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
