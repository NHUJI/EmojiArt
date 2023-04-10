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
                ).gesture(doubleTapToZoom(in: geometry.size).simultaneously(with: deleteSelectedEmojis())) // 双击缩放背景图片到合适大小
                // 显示背景图片加载状态
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2) // 加载图标
                } else {
                    // 表情显示
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(emojiSize(for: emoji)) // 缩放
                            .position(position(for: emoji, in: geometry))
                            .gesture(tapToSelect(emoji: emoji).simultaneously(with: isSelected(emoji) ? panEmojiGesture(on: emoji) : nil)) // 点击选择表情
                            .overlay(
                                // 如果表情被选中,则显示边框
                                selectedEmojisOverlay(for: emoji, in: geometry)
                            )
                    }
                }
            }
            .clipped() // 裁剪超出视图的部分(也就是图片不会占据表情选择滚动条了)
            // 使视图可以接受拖拽表情和背景图片
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(zoomGesture().simultaneously(with: selectedEmojis.isEmpty ? panGesture() : nil)) // 当偏移量为0时,才检测移动手势
            // 不要在一个view上使用多个gesture,所以使用simultaneously同时检测移动和缩放手势
        }
    }

    // MARK: - 表情在缩放手势时的大小

    private func emojiSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        // 没选择表情时就正常返回总体的缩放量
        if selectedEmojis.isEmpty {
            return zoomScale
        } else {
            // 如果表情被选择,添加缩放量
            if isSelected(emoji) {
                return steadyStateZoomScale * gestureZoomScale
            } else {
                return steadyStateZoomScale
            }
        }
    }

    // MARK: - 表情(放置)

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

    // MARK: - 选择的表情移动

    @GestureState private var gestureEmojiPanOffset: CGSize = .zero // 移动时的偏移量

    // 选择表情移动手势
    private func panEmojiGesture(on _: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
                gestureEmojiPanOffset = latestDragGestureValue.translation / zoomScale
                // 打印偏移量
                // print("gestureEmojiPanOffset: \(gestureEmojiPanOffset)")
            }
            .onEnded { finalDragGestureValue in
                for emojiId in selectedEmojis {
                    document.moveEmoji(emojiId, by: finalDragGestureValue.translation / zoomScale)
                }
                // 打印偏移量
                // print("finalDragGestureValue: \(finalDragGestureValue.translation / zoomScale)")
            }
    }

    // MARK: - 表情选择

    // 存储表情(emoji)的集合
    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []

    // 点击选择/取消选择表情
    private func tapToSelect(emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                // if selectedEmojis.contains(emoji.id) {
                //     selectedEmojis.remove(emoji.id)
                // } else {
                //     selectedEmojis.insert(emoji.id)
                // }
                // 以上代码可以简化为:
                selectedEmojis.toggleMembership(of: emoji)

                // 把表情加入selectedEmojisDict字典

                // 打印选择的表情
                // print(emoji.id)
            }
    }

    // 表情是否被选择(用emoji的id属性来判断)
    private func isSelected(_ emoji: EmojiArtModel.Emoji) -> Bool {
        var isSelected = false
        let emojiId = emoji.id
        selectedEmojis.forEach {
            if $0.id == emojiId {
                isSelected = true
            }
        }
        return isSelected
    }

    // 选择表情后的方框效果
    private func selectedEmojisOverlay(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: fontSize(for: emoji) * emojiSize(for: emoji) + 10, height: fontSize(for: emoji) * emojiSize(for: emoji) + 10) // 计算边框大小
            .position(position(for: emoji, in: geometry))
            .opacity(isSelected(emoji) ? 1 : 0) // 如果表情被选中,则显示边框
    }

    // 删除全部选中的表情
    private func deleteSelectedEmojis() -> some Gesture {
        TapGesture(count: 1)
            .onEnded {
                selectedEmojis.removeAll()
            }
    }

    // MARK: - 表情(放置)

    // 根据emoji的大小来设置字体大小(每个表情的大小可能不一样)
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }

    // 根据emoji的坐标来设置表情的位置(每个表情的位置可能不一样)
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        // 如果表情被选择,添加偏移量
        if isSelected(emoji) {
            return convertFromEmojiCoordinates((emoji.x + Int(gestureEmojiPanOffset.width), emoji.y + Int(gestureEmojiPanOffset.height)), in: geometry)
        } else {
            return convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
        }
    }

    // 将表情的坐标转换为视图的坐标的辅助函数
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center // .center是扩展引入的
        return CGPoint(
            // 需要适应缩放比例,所以要乘以缩放比例
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }

    // 将视图的坐标转换为表情的坐标的辅助函数
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }

    // MARK: - 背景图片和表情调整手势

    // 缩放背景图片相关的函数
    @State private var steadyStateZoomScale: CGFloat = 1.0 // doc缩放比例
    @GestureState private var gestureZoomScale: CGFloat = 1.0 // 只在捏合时改变的缩放比例

    // 计算缩放比例
    private var zoomScale: CGFloat {
        if selectedEmojis.isEmpty {
            return steadyStateZoomScale * gestureZoomScale
        } else {
            return steadyStateZoomScale // 如果有表情被选中,则不允许缩放所以元素
        }
    }

    // 缩放拖入的背景图片的辅助函数
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // 首先判断图片是否存在,然后图片的宽高是否大于0,再判断传入的size是否大于0
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            // 计算缩放比例
            let hZoom = size.width / image.size.width // 水平缩放比例
            let vZoom = size.height / image.size.height // 垂直缩放比例
            steadyStatePanOffset = .zero // 重置拖拽偏移量
            steadyStateZoomScale = min(hZoom, vZoom) // 选择宽高中较小的作为缩放比例(也就是图片不会超出视图)
        }
    }

    // 返回一个双击缩放背景图片的手势
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2) // 双击
            .onEnded { // 也就是第二次点击的时候
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size) // 缩放背景图片
                }
            }
    }

    // 返回一个捏合缩放的手势(也会用在被选择的表情上)
    private func zoomGesture() -> some Gesture {
        MagnificationGesture() // 捏合手势
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale // updating的作用是持续用最新的捏合比例更新gestureZoomScale
            }.onEnded { gestureScaleEnd in
                if selectedEmojis.isEmpty { // 如果没有选中表情,则缩放背景图片
                    steadyStateZoomScale *= gestureScaleEnd // 更新缩放比例
                } else { // 如果选中了表情,则缩放表情
                    selectedEmojis.forEach { emoji in
                        document.scaleEmoji(emoji, by: gestureScaleEnd)
                    }
                }
            }
    }

    // 长按移动文档相关的函数
    @State private var steadyStatePanOffset: CGSize = .zero // doc移动的偏移量
    @GestureState private var gesturePanOffset: CGSize = .zero // 只在拖动时改变的偏移量

    // 计算偏移量(用于背景图片和表情在拖动手势下的移动)
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale // 扩展里增加了让size相加的功能
    }

    // 返回一个拖动背景图片的手势
    private func panGesture() -> some Gesture {
        DragGesture() // 拖动手势
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale // 不使用translation,所以用_替代
            }.onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale) // 更新偏移量
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
