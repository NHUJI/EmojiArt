//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import Foundation

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()

    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int
        var y: Int
        var size: Int
        let id: Int

        // fileprivate表示只有本文件的代码可以访问,避免id被外部修改
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }

    init() {} // 设置EmojiArtModel的默认构造函数(什么都不干),避免被用来设置背景和emoji
    private var uniqueEmojiId = 0 // 用于给每个emoji分配唯一的id

    // 由于修改了本身的属性，所以需要加上mutating, (x: Int, y: Int)是一个元组(tuple)，用于表示一个坐标
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1 // 为每个添加的emoji分配一个唯一的id
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }

    // 删除表情
    mutating func deleteEmoji(_ emoji: Emoji) {
        emojis.removeAll(where: { $0.id == emoji.id }) // 使用id判断避免删除错误
    }
}
