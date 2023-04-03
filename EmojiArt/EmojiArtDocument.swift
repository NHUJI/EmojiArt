//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  VM of MVVM
//  Created by huhu on 2023/4/1.
//

import SwiftUI

class EmojiArtDocument: ObservableObject
{
    // @Published表示当emojiArt发生变化时，会自动通知所有的观察者
    @Published private(set) var emojiArt: EmojiArtModel
    
    init(){
        emojiArt = EmojiArtModel()
        // 测试用,添加几个不同的emoji
        emojiArt.addEmoji("👻", at: (-200, 100), size: 80)
        emojiArt.addEmoji("🎃", at: (100, 0), size: 40)
        emojiArt.addEmoji("🤡", at: (0, -100), size: 30)


        
    }
    
    // 方便使用EmojiArt.Emoji直接获取emojis
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    // MARK: - Intent(s) 通过这些方法来修改emojiArt
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
    
    
}
