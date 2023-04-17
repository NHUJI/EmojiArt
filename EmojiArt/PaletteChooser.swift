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

    @EnvironmentObject var store: PaletteStore // 通过注入到视图的方式获取store(model)

    @State private var chosenPaletteIndex = 0 // 当前选择的palette的index

    var body: some View {
        HStack {
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped() // 让切换动画不会超出表情选择栏的边界
    }

    var paletteControlButton: some View {
        Button { // 每次点击就切换到下一个palette
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count // 通过取余的方式循环切换palette
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont) // 设置成和表情一样大
        .contextMenu { contextMenu } // 设置长按弹出的菜单
    }

    @ViewBuilder // ViewBuilder可以让我们在一个函数中返回多个view 
    var contextMenu: some View {
        // AnimatedActionButton是自定义的扩展,方便做菜单按钮
        AnimatedActionButton(title: "Edit", systemImage: "pencil") {
            //    editing = true // 进入编辑模式
            // paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            // 调用model的方法,便捷地添加一个新的palette
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
            //    editing = true
            // paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
            // removePalette会返回新的index,所以可以在这里直接改变chosenPaletteIndex
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
//            managing = true
        }
        gotoMenu // 跳转到二级菜单选择表情组
    }

    // 点击选择需要跳转的表情组,不需要@ViewBuilder,因为只有一个Menu view
    var gotoMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButton(title: palette.name) {
                    // index(matching:)是自定义的扩展,用于获取palette在palettes中的index
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "text.insert")
        }
    }

    // 独立出来的palette的名字和表情内容
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojisView(emojis: palette.emojis) // 由testemojis更改为真实的表情
                .font(.system(size: emojiFontSize))
        }
        .id(palette.id) // 相当于让这个view identifiable,这样就可以使用transition了(因为之前只是在更新里面的值并没有改变view)
        .transition(rollTransition) // 设置切换动画
    }

    // palette切换动画
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric( // 由于从下面出现、上面离去,不在同一个地方,所以需要使用asymmetric(不对称)
            insertion: .offset(x: 0, y: emojiFontSize), // 没有水平偏移,只有垂直偏移,他的偏移量设置为emoji的大小(可以根据表情字体大小动态改变)
            removal: .offset(x: 0, y: -emojiFontSize)
        )
    }
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
