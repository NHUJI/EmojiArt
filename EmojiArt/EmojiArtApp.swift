//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    // 创建一个用于演示的 document,从let更改为@StateObject var方便我们搜索到source of truth
    @StateObject var document = EmojiArtDocument()
    // 通过创建这个PaletteStore,当app启动时会自动从UserDefaults中恢复数据(用于调试功能,因为还没有实现Document加入UI)
    @StateObject var paletteStore = PaletteStore(named: "Default")

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
                .environmentObject(paletteStore) // 在所有它和所有子视图中注入这个paletteStore
        }
    }
}
