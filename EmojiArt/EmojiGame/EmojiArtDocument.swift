//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  VM of MVVM
//  Created by huhu on 2023/4/1.
//

import Combine // 用于发布者和订阅者模式
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "nhuji.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument {
    static var readableContentTypes = [UTType.emojiart]
    static var writeableContentTypes = [UTType.emojiart]

    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json() // 如何表示这个文件(直接用doc的json化方法)
    }

    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
        // 自动保存的逻辑:emojiArt改变,触发上面的snapshot(另一个线程),再在这里面包裹着
    }

    // @Published表示当emojiArt发生变化时，会自动通知所有的观察者
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }

    init() {
        emojiArt = EmojiArtModel()
        // 添加3000个随机的emoji
//        for _ in 0 ..< 3000 {
//            let emojis = ["👻", "😀", "😎", "🐶", "🐱", "🦁", "🐯", "🐻", "🐼", "🐨"]
//            let randomEmoji = emojis.randomElement()!
//            emojiArt.addEmoji(randomEmoji, at: (Int.random(in: -300...300), Int.random(in: -300...300)), size: Int.random(in: 1...5))
//        }
    }

    // 方便使用EmojiArt.Emoji直接获取emojis
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }

    // @Published表示当backgroundImage发生变化时，会自动通知所有的观察者
    // 另外UIImage设置为可选项,因为可能没有背景图片(比如url对应的不是图片)
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle // 设置一个状态,用来表示当前的背景图片的状态(通过检测enum的值来判断)

    enum BackgroundImageFetchStatus: Equatable { // 有关联值的枚举,所以需要遵守Equatable协议
        case idle // 空闲状态
        case fetching // 正在获取图片
        case failed(URL) // 获取图片失败(用于弹出警告)
    }

    private var backgroundImageFetchCancellable: AnyCancellable? // 用于存储publisher的引用(需要import Combine)

    private func fetchBackgroundImageDataIfNecessary() {
        // 根据背景的状态来进行不同的操作
        backgroundImage = nil // 先清空背景图片
        switch emojiArt.background {
        case .url(let url):
            // 如果是url,则异步加载图片
            backgroundImageFetchStatus = .fetching // 设置状态为正在获取图片

            backgroundImageFetchCancellable?.cancel() // 先取消之前的publisher(避免上一次设置的图片还没完成)
            // 使用URLSession来获取图片
            let session = URLSession.shared // 它就是一个获取url的小session,完成获取后就callback
            // 创建publisher
            let publisher = session.dataTaskPublisher(for: url) // 返回一个publisher,它的输出是一个元组,包含data和response)
                .map { data, _ in UIImage(data: data) } // 只需要data,所以使用map来转换,将data转换为UIImage
                .replaceError(with: nil) // 将可能出现的错误替换为nil
                .receive(on: DispatchQueue.main) // 将publisher的输出放入主线程中(因为UI只能在主线程中更新)

            // 放入背景变量(只要self还在,这个publisher就会一直运行,关闭doc时也会自动停止)
            backgroundImageFetchCancellable = publisher
                // assign不能在结束时自动取消,也不能改变BackgroundImageFetchStatus
                // .assign(to: \.EmojiArtDocument.backgroundImage, on: self) // 将publisher的输出放入backgroundImage中
                .sink { [weak self] image in // 由于处理量错误为never,不需要receiveCompletion了
                    self?.backgroundImage = image
                    self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
                }

            // 这一步会导致线程阻塞,所以需要使用多线程异步加载
            // let imageData = try? Data(contentsOf: url) // try?表示如果出错,则返回nil

            // // 异步加载图片
            // DispatchQueue.global(qos: .userInitiated).async {
            //     let imageData = try? Data(contentsOf: url) // try?表示如果出错,则返回nil

            //     // 回到主线程
            //     DispatchQueue.main.async { [weak self] in // 表示这个闭包是一个弱引用,如果其他地方不需要了,则会自动释放
            //         // 保证当前加载的图片还是用户想要的(通过检查当前已经获取到图片的url和model中设置的url是否一致)
            //         // 例子:用户拖拽了一个url,但加载非常缓慢,此时用户又拖拽了一个url,加载很快,如果没有这个判断这个之前拖拽的图片就会在加载好后覆盖新的图片
            //         if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
            //             self?.backgroundImageFetchStatus = .idle // 设置状态为空闲
            //             // 如果图片数据不为空,则加载图片(UI相关的操作应该在主线程中进行)
            //             if imageData != nil {
            //                 // 之所以要加self,是因为queue中的代码是一个闭包,通过self来让闭包这个引用类型指向我们的VM
            //                 //  即使VM关闭了还是会因为闭包的引用而不会被释放(所以通过加入[weak self]解决)

            //                 // self.backgroundImage = UIImage(data: imageData!)
            //                 self?.backgroundImage = UIImage(data: imageData!) // “?”表示如果self为nil,则不执行后面的代码
            //             }
            //             if self?.backgroundImage == nil {  // 如果图片数据为空,则设置状态为获取失败
            //                 self?.backgroundImageFetchStatus = .failed(url)
            //             }
            //         }
            //     }
            // }

        case .imageData(let data):
            // 如果是图片数据,则直接加载图片
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }

    // MARK: - Intent(s) 通过这些方法来修改emojiArt

    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager) {
            emojiArt.background = background
        }
    }

    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager) {
            emojiArt.addEmoji(emoji, at: location, size: Int(size))
        }
    }

    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            undoablyPerform(operation: "Move", with: undoManager) {
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }

    // 我自己的修改,加入了限制表情最大最小大小的功能
    private let minEmojiSize: CGFloat = 10
    private let maxEmojiSize: CGFloat = 600

    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            var newSize = CGFloat(emojiArt.emojis[index].size) * scale
            newSize = min(max(newSize, minEmojiSize), maxEmojiSize) // 限制大小在[minEmojiSize, maxEmojiSize]范围内
            undoablyPerform(operation: "Scale", with: undoManager) {
                emojiArt.emojis[index].size = Int(newSize.rounded(.toNearestOrAwayFromZero))
            }
        }
    }

    func deleteEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.deleteEmoji(emoji)
    }

    // MARK: - Undo

    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: () -> Void) {
        let oldEmojiArt = emojiArt // 获得model的一个副本
        doit() // 执行闭包(也就是修改model的操作)
        undoManager?.registerUndo(withTarget: self) { myself in
            // 实现redo
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt // 让model回到撤消前的状态
            }
        }
        undoManager?.setActionName(operation) // 设置撤消的操作名(macOS中会显示在菜单栏中)
    }
}
