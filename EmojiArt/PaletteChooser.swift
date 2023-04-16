//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/16.
//  也就是Palette的MVVM的View

import SwiftUI

struct PaletteChooser: View {
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize) }

    var body: some View {
        ScrollingEmojisView(emojis: testemojis)
            .font(.system(size: emojiFontSize))
    }

    let testemojis = "🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🚚🚛🚜🛴🚲🛵🏍🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉✈️🛫🛬🚀🛸🚁🛶⛵️🚤🛥🛳⛴🚢⚓️🚧🚦🚥🚏🗺🗿🗽🗼🏰🏯🏟🎡🎢🎠⛲️"
}

// 用于显示下方的表情的滚动条
struct ScrollingEmojisView: View {
    let emojis: String
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                // 由于使用了\.self(也就是这个emoji本身)作为id,所以需要用removingDuplicateCharacters去除重复的palette
                ForEach(emojis.removingDuplicateCharacters.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) } // 拖拽表情功能,使用了NSItemProvider(UIKit),另外它是异步的所以不会阻塞主线程
                }
            }
        }
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
    }
}
