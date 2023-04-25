//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import Foundation

extension EmojiArtModel {
    // 背景可能是空的，也可能是URL(用于加载网络图片)，也可能是图片数据
    enum Background: Equatable, Codable {
        case blank
        case url(URL) // (URL)表示需要关联数据
        case imageData(Data)

        // MARK: - Codable
        // 为了让enum在有关联数据的情况下也可以被Codable,需要自己实现编码和解码的方法(swift5.5后不需要了)

        /*
        解码方法
        代码首先创建了一个容器来存储编码数据。
        然后，它尝试从容器中解码一个URL对象。如果成功，则将枚举类型设置为.url(url)。
        否则，它尝试从容器中解码一个Data对象。如果成功，则将枚举类型设置为.imageData(imageData)。
        否则，将枚举类型设置为.blank
        */
        init(from decoder: Decoder) throws {
            // 在Swift中，self关键字用于引用当前实例或类型,也就是把CodingKeys实际的类型传入keyedBy表示使用这种类型去解码
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // let表示如果我能让url等于那个容器就怎么怎么样
            // 这里使用try?的逻辑是如果解码失败就返回nil然后url = nil就失败然后就会进入else if继续检查
            // 也就是说当有问题时不是必须 re thorw error的,而是使用try?这样返回nil
            if let url = try? container.decode(URL.self, forKey: .url) { // 这里的 forKey: .url和编码时一致,所以能够分辨
                self = .url(url) // 如果“我”是url就把self(这个enum)设置为url
            } else if let imageData = try? container.decode(Data.self, forKey: .imageData) {
                self = .imageData(imageData)
            } else {
                self = .blank
            }
        }
        
        // CodingKeys枚举类型提供了编码和解码过程中需要的键。它允许您指定在编码和解码过程中使用的键，以便将数据存储在容器中
        // 所以CodingKey基本只是表示CodingKeys可以被keyedBy使用
        enum CodingKeys: String, CodingKey {
            case url = "theURL" // 自定义了原始值用于存储时使用(可以在json文件中看到)
            case imageData
        }
        
        /* 
        编码方法
        代码首先创建了一个容器来存储编码数据
        然后，它根据枚举类型的当前值进行匹配。如果当前值是.url(let url)，
        则将URL对象编码到容器中；如果当前值是.imageData(let data)，则将Data对象编码到容器中；
        如果当前值是.blank，则不执行任何操作
        encode(to:)函数会在枚举类型实例被编码时自动调用。它负责处理枚举类型的关联值，并将它们编码为可存储的数据
         */
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            // 表示根据当前的枚举类型来编码,如果“我”是xxx就编码成xxx
            switch self {
                // 添加了try,表示如果编码失败就抛出异常(之所以要try又是因为encode本身也会抛出异常)
            case .url(let url): try container.encode(url, forKey: .url) // forKey里的值必须和CodingKeys中的值一致
            case .imageData(let data): try container.encode(data, forKey: .imageData)
            case .blank: break
            }
        }
        
        
        // 语法糖，用于直接接收各种数据,比如url和image作为背景
        var url: URL? {
            switch self {
            case .url(let url): return url
            default: return nil
            }
        }

        var imageData: Data? {
            switch self {
            case .imageData(let data): return data
            default: return nil
            }
        }
    }
}
