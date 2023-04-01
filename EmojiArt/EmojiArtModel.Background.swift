//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/1.
//

import Foundation

extension EmojiArtModel{
    // 背景可能是空的，也可能是URL(用于加载网络图片)，也可能是图片数据
    enum Background {
        case blank
        case url(URL) // (URL)表示需要关联数据
        case imageData(Data)

        // 语法糖，用于直接获取关联数据
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
