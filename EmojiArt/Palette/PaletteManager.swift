//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/18.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore

    // @Environment(\.colorScheme) var colorScheme // 其实简单的说就是用EeviromentValue里的\.colorScheme来创建变量colorScheme

    // a Binding to a PresentationMode
    // which lets us dismiss() ourselves if we are isPresented
    // 用于返回按钮,一般不会自己创建相关的本地变量
    @Environment(\.presentationMode) var presentationMode

    // we inject a Binding to this in the environment for the List and EditButton
    // using the \.editMode in EnvironmentValues
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List { // 和VStack有点类似,不过可以支持很多特性
                ForEach(store.palettes) { palette in
                    // 点击跳转到编辑框(复用) ,NavigationLink只在NavigationView中有效
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) { // 传入了binding方便修改
                        VStack(alignment: .leading) { // 排列在左边
                            Text(palette.name)
                            // .font(editMode == .active ? .largeTitle : .caption)
                            Text(palette.emojis)
                        } 
                        // tapping when NOT in editMode will follow the NavigationLink
                        // (that's why gesture is set to nil in that case)
                    
                        .gesture(editMode == .active ? tap : nil)
                    }
                }
                .onDelete { indexSet in // 删除,indexSet也就是循环里对应表情组的索引(虽然叫set但一次只能删除一个,不过以后可能支持多个)
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in // 移动
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes") // 设置标题
            .navigationBarTitleDisplayMode(.inline) // 设置标题显示方式(还有.large)
            // .environment(\.colorScheme, .dark) // 设置环境变量(只对注入的view有效)
            .toolbar {
                ToolbarItem { EditButton() } // 用于编辑模式切换按钮(swiftUI自带)
                ToolbarItem(placement: .navigationBarLeading) { // 按钮位置
                    if presentationMode.wrappedValue.isPresented, // 由于是绑定,通过wrappedValue来查看值,如果是presented就显示返回按钮
                       UIDevice.current.userInterfaceIdiom != .pad
                    { // 如果是iPad就不显示返回按钮(iPad可以直接点击空白区域关闭)
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss() // 用dismiss来关闭页面
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode) // 使用了绑定来修改和显示编辑模式
        }
    }

    var tap: some Gesture {
        TapGesture().onEnded { }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .previewDevice("iPhone 14")
            .environmentObject(PaletteStore(named: "Preview"))
//            .preferredColorScheme(.dark)
//            .preferredColorScheme(.light)
    }
}
