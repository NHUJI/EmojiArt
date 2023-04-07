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
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle // 设置一个状态,用来表示当前的背景图片的状态(通过检测enum的值来判断)

    enum BackgroundImageFetchStatus: Equatable {
        case idle // 空闲状态
        case fetching // 正在获取图片
        case failed(URL) // 获取图片失败
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
                        if imageData == nil {
                            // 如果图片数据为空,则设置状态为获取失败
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

    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
