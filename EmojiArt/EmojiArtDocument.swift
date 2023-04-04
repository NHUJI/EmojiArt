//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  VM of MVVM
//  Created by huhu on 2023/4/1.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    // @Published表示当emojiArt发生变化时，会自动通知所有的观察者
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            // 当emojiArt发生变化时,会自动调用这里的代码
            if emojiArt.background != oldValue.background {
                // 如果背景图片发生变化,则重新加载图片
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }

    init() {
        emojiArt = EmojiArtModel()
        // 测试用,添加几个不同的emoji
        emojiArt.addEmoji("👻", at: (-200, 100), size: 80)
        emojiArt.addEmoji("🎃", at: (100, 0), size: 40)
        emojiArt.addEmoji("🤡", at: (0, -100), size: 30)

        // 添加30个类似的测试用例
        //        for i in 0..<30{
        //            emojiArt.addEmoji("👻", at: (Int.random(in: -300...300), Int.random(in: -300...300)), size: Int.random(in: 10...100))
        //        }
    }

    // 方便使用EmojiArt.Emoji直接获取emojis
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }

    // @Published表示当backgroundImage发生变化时，会自动通知所有的观察者
    // 另外UIImage设置为可选项,因为可能没有背景图片(比如url对应的不是图片)
    @Published var backgroundImage: UIImage?

    private func fetchBackgroundImageDataIfNecessary() {
        // 根据背景的状态来进行不同的操作
        backgroundImage = nil // 先清空背景图片
        switch emojiArt.background {
        case .url(let url):
            // 如果是url,则异步加载图片

            // 这一步会导致线程阻塞,所以需要使用多线程
            let imageData = try? Data(contentsOf: url) // try?表示如果出错,则返回nil

            if imageData != nil {
                // 如果图片数据不为空,则加载图片
                backgroundImage = UIImage(data: imageData!) // imageData!表示强制解包,因为上面已经判断过不为空了
            }

        case .imageData(let data):
            // 如果是图片数据,则直接加载图片
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }

    // MARK: - Intent(s) 通过这些方法来修改emojiArt

    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background set to \(background)")
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
