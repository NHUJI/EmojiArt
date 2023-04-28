//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Default")

    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore) // 在所有它和所有子视图中注入这个paletteStore
        }
    }
}
