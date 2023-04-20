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
            // 当emojiArt发生变化时,会调用自动保存功能(它会合并更改并在停止更改后一段时间后自动保存)
            scheduleAutosave()
            // 当emojiArt发生变化时,会自动调用这里的代码
            if emojiArt.background != oldValue.background {
                // 如果背景图片发生变化,则重新加载图片
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }

    // 用于自动保存的timer
    private var autosaveTimer: Timer?

    private func scheduleAutosave() {
        // 如果timer已经存在,则取消它(避免每次保存都开始计时,失去合并的意义)
        autosaveTimer?.invalidate()
        // 我们不需要timer的引用,所以用_来代替,另外不需要使用weak self
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
            self.autosave()
        }
    }

    // Autosave用于存储自动保存的文件名和url
    private enum Autosave {
        // 定义自动保存文件使用的文件名
        static let filename = "Autosaved.emojiart"
        // 计算属性，用于获取自动保存文件的 URL
        static var url: URL? {
            // 获取文档目录的URL
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            // 在文档目录的 URL 后面添加文件名，得到自动保存的文件的URL(也就是之前只是获得文件夹现在加上具体的名称)
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0 // 自动保存的时间间隔
    }

    // 自动保存
    private func autosave() {
        // 如果url不为空,则保存到这个url中
        if let url = Autosave.url {
            save(to: url)
        }
    }

    // 这里的URL和拖入图片的不同,这是文件URL 用于放入本地存储中
    // 这里不打算再抛出错误了,而是使用do-catch来处理错误
    private func save(to url: URL) {
        //  由于可能处理多种错误,所以存储结构名和方法名
        let thisFunction = "\(String(describing: self)).\(#function))"
        do {
            // 将emojiArt模型转换为json格式的数据
            let data: Data = try emojiArt.json() // 让模型提供一个方法把自己转换为json格式的数据
            print("\(thisFunction) json=\(String(data: data, encoding: .utf8) ?? "nil")") // 打印json格式的数据
            // 将数据保存到url中
            try data.write(to: url)
            // 在这两个之后表示没有错误
            print("\(thisFunction) success!")
        } catch let encodingError where encodingError is EncodingError { // 只捕获 EncodingError 类型的错误
            print("\(thisFunction) couldn't encode EmojiArt as JsoN because \(encodingError.localizedDescription)")
        } catch {
            print("\(thisFunction) error= \(error)")
        }
    }

    init() {
        // 首先尝试从本地加载自动保存的数据,如果成功,则使用这个数据,否则使用默认的数据(空白页面)
        if let url = Autosave.url, let autusavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autusavedEmojiArt
            // 如果加载成功,则尝试加载背景图片
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        // 测试用,添加几个不同的emoji
        emojiArt.addEmoji("👻", at: (-200, 100), size: 80)
        emojiArt.addEmoji("🎃", at: (100, 0), size: 40)
        emojiArt.addEmoji("🤡", at: (0, -100), size: 30)
        }

        

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
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle // 设置一个状态,用来表示当前的背景图片的状态(通过检测enum的值来判断)

    enum BackgroundImageFetchStatus: Equatable { // 有关联值的枚举,所以需要遵守Equatable协议
        case idle // 空闲状态
        case fetching // 正在获取图片
        case failed(URL) // 获取图片失败(用于弹出警告)
    }

    private func fetchBackgroundImageDataIfNecessary() {
        // 根据背景的状态来进行不同的操作
        backgroundImage = nil // 先清空背景图片
        switch emojiArt.background {
        case .url(let url):
            // 如果是url,则异步加载图片
            backgroundImageFetchStatus = .fetching // 设置状态为正在获取图片
            // 这一步会导致线程阻塞,所以需要使用多线程异步加载
            // let imageData = try? Data(contentsOf: url) // try?表示如果出错,则返回nil
            // 异步加载图片
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = try? Data(contentsOf: url)

                // 回到主线程
                DispatchQueue.main.async { [weak self] in // 表示这个闭包是一个弱引用,如果其他地方不需要了,则会自动释放
                    // 保证当前加载的图片还是用户想要的(通过检查当前已经获取到图片的url和model中设置的url是否一致)
                    // 例子:用户拖拽了一个url,但加载非常缓慢,此时用户又拖拽了一个url,加载很快,如果没有这个判断这个之前拖拽的图片就会在加载好后覆盖新的图片
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self?.backgroundImageFetchStatus = .idle // 设置状态为空闲
                        // 如果图片数据不为空,则加载图片(UI相关的操作应该在主线程中进行)
                        if imageData != nil {
                            // 之所以要加self,是因为queue中的代码是一个闭包,通过self来让闭包这个引用类型指向我们的VM
                            //  即使VM关闭了还是会因为闭包的引用而不会被释放(所以通过加入[weak self]解决)

                            // self.backgroundImage = UIImage(data: imageData!)
                            self?.backgroundImage = UIImage(data: imageData!) // “?”表示如果self为nil,则不执行后面的代码
                        }
                        if self?.backgroundImage == nil {  // 如果图片数据为空,则设置状态为获取失败
                            self?.backgroundImageFetchStatus = .failed(url)
                        }
                    }
                }
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
        // print("background set to \(background)")
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

//    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
//        if let index = emojiArt.emojis.index(matching: emoji) {
//            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
//        }
//    }
    // 我自己的修改,加入了限制表情最大最小大小的功能
    private let minEmojiSize: CGFloat = 10
    private let maxEmojiSize: CGFloat = 600

    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            var newSize = CGFloat(emojiArt.emojis[index].size) * scale
            newSize = min(max(newSize, minEmojiSize), maxEmojiSize) // 限制大小在[minEmojiSize, maxEmojiSize]范围内
            emojiArt.emojis[index].size = Int(newSize.rounded(.toNearestOrAwayFromZero))
        }
    }

    func deleteEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.deleteEmoji(emoji)
    }
}
