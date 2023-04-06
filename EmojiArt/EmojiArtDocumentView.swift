//
//  EmojiArtDocumentView.swift
//  EmojiArt
//  View of MVVM
//
//  Created by huhu on 2023/4/1.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    // 通过@ObservedObject来观察document的变化,document是EmojiArtDocument(MVVM的VM)
    @ObservedObject var document: EmojiArtDocument

    let defaultEmojiFontSize: CGFloat = 40

    // app的主体视图
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片,使用了扩展的OptionalImage替代Image以接收可选值
                // 使用了overlay,所以如果背景图片为空,则会显示白色
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale) // 缩放
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                ).gesture(doubleTapToZoom(in: geometry.size)) // 双击缩放背景图片到合适大小
                // 显示背景图片加载状态
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2) // 加载图标
                } else {
                    // 表情显示
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale) // 缩放
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped() // 裁剪超出视图的部分(也就是图片不会占据表情选择滚动条了)
            // 使视图可以接受拖拽表情和背景图片
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
        }
    }

    // 拖拽表情到视图的功能
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            // 如果是图片url,则添加图片背景
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }

        if !found {
            found = providers.loadFirstObject(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    // 如果是图片,则添加图片背景
                    document.setBackground(.imageData(data)) // 可以省略EmojiArtModel.Background,swift能够推断出来
                }
            }
        }

        if !found {
            // 如果是文本,则添加表情(通过loadFirstObject扩展来获取文本)
            found = providers.loadFirstObject(ofType: String.self) { string in
                // 保证是emoji
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale // 适应缩放比例,保持表情大小不变
                    ) // 添加表情
                }
            }
        }
        return found
    }

    // 根据emoji的大小来设置字体大小(每个表情的大小可能不一样)
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }

    // 根据emoji的坐标来设置表情的位置(每个表情的位置可能不一样)
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }

    // 将表情的坐标转换为视图的坐标的辅助函数
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center // .center是扩展引入的
        return CGPoint(
            // 需要适应缩放比例,所以要乘以缩放比例
            x: center.x + CGFloat(location.x) * zoomScale,
            y: center.y + CGFloat(location.y) * zoomScale
        )
    }

    // 将视图的坐标转换为表情的坐标的辅助函数
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: location.x - center.x / zoomScale,
            y: location.y - center.y / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }

    // 缩放背景图片相关的函数
    @State private var zoomScale: CGFloat = 1.0 // doc缩放比例
    // 缩放拖入的背景图片的辅助函数
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // 首先判断图片是否存在,然后图片的宽高是否大于0,再判断传入的size是否大于0
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            // 计算缩放比例
            let hZoom = size.width / image.size.width // 水平缩放比例
            let vZoom = size.height / image.size.height // 垂直缩放比例
            zoomScale = min(hZoom, vZoom) // 选择宽高中较小的作为缩放比例  
        } 
    }
    // 返回一个双击缩放背景图片的手势
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2) // 双击
            .onEnded { //也就是第二次点击的时候
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size) // 缩放背景图片
                }
            }
    }


    // 选择表情的滚动条
    var palette: some View {
        ScrollingEmojisView(emojis: testemojis)
            .font(.system(size: defaultEmojiFontSize))
    }

    let testemojis = "🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🚚🚛🚜🛴🚲🛵🏍🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉✈️🛫🛬🚀🛸🚁🛶⛵️🚤🛥🛳⛴🚢⚓️🚧🚦🚥🚏🗺🗿🗽🗼🏰🏯🏟🎡🎢🎠⛲️"
}

// 用于显示下方的表情的滚动条
struct ScrollingEmojisView: View {
    let emojis: String
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag { NSItemProvider(object: emoji as NSString) } // 拖拽表情功能,使用了NSItemProvider(UIKit),另外它是异步的所以不会阻塞主线程
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
