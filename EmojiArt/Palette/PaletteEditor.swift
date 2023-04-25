//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/17.
//  编辑表情组的视图

import SwiftUI

struct PaletteEditor: View {
    // @State private var palette: Palette = PaletteStore(named: "Test").palette(at: 1) // 测试用的model
    @Binding var palette: Palette // 由其他地方传入

    var body: some View {
        // Form可以提供类似系统默认的表单样式
        Form {
            nameSection
            addEmojisSection
            removeEmojiSection
        }
        .frame(minWidth: 300, minHeight: 350) // 还有很多其他参数,我们只设置了最小宽高
        .navigationTitle("Edit \(palette.name)") // 设置导航栏标题(只在Navigation导航过来时有效)
    }

    // 独立出来的Section,让Form更简洁
    var nameSection: some View {
        Section(header: Text("Name")) { // 使用Section可以加上显示的标题
            TextField("Name", text: $palette.name) // 通过$palette.name来绑定model的name属性来同步修改
        }
    }

    @State private var emojisToAdd = ""

    var addEmojisSection: some View {
        Section(header: Text("Add Emojis")) {
            // 不能直接绑定palette.emoji但又想修改的话就可以先绑定到一个临时变量上然后通过onChange来监听变化
            TextField("", text: $emojisToAdd) // 还可以用onCommit{}来在用户回车时提交,还有onEditingChanged{}来监听用户是否正在编辑等
                .onChange(of: emojisToAdd) { emojis in
                    addEmojis(emojis) // 每次输入就添加表情
                }
        }
    }

    // 在原有的表情组上添加新的表情
    func addEmojis(_ emojis: String) {
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter { $0.isEmoji } // 确保是表情(isEmoji也是扩展)
                .removingDuplicateCharacters // 去重
        }
    }

    var removeEmojiSection: some View {
        Section(header: Text("Remove Emoji")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .onTapGesture { // 点击表情就删除
                            withAnimation {
                                palette.emojis.removeAll(where: { String($0) == emoji })
                            }
                        }
                }
            }
            .font(.system(size: 40))
        }
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        // 使用Binding.constant(绑定到常量值)来预览
        PaletteEditor(palette: .constant(PaletteStore(named: "Test").palette(at: 2)
        ))
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/))
        PaletteEditor(palette: .constant(PaletteStore(named: "Test").palette(at: 2)
        ))
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: 600))
    }
}
