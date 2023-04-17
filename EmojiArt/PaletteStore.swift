//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by huhu on 2023/4/15.
//  也就是Palette的MVVM的VM

import SwiftUI

// Identifiable非常重要,因为UI经常要用它forEach等
struct Palette: Identifiable, Codable, Hashable {
    // 为了后面可以更改调色盘,所以设置为var而不是let
    var name: String // emoji种类的名称
    var emojis: String // 可以选择的表情列表(会被分解成数组)
    var id: Int // 用于标识的id

    // 表示只能通过这个VM来添加新的palette
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

// 所有的VM都是ObservableObject的(代表它们是可观察的)
class PaletteStore: ObservableObject {
    let name: String

    // MVVM的model
    @Published var palettes = [Palette]() {
        // 每次更改时保存数据
        didSet {
            storeInUserDefaults()
        }
    }

    // 用于存储数据的key
    private var userDefaultsKey: String { "PaletteStore:\(name)" }

    // 存储palettes
    private func storeInUserDefaults() {
        // 如果失败会被设置成nil(预防比如key出问题时等)
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)

        // 放弃使用的策略,转为用Codable来把数据变成Json存储
        // UserDefaults.standard.set(
        //     // 由于UserDefaults API古老,所以需要通过map把palettes转换成PropertyList来存储(会创建字符串数组 )
        //     palettes.map { [$0.name, $0.emojis, String($0.id)] }, forKey: userDefaultsKey
        // )
    }

    // 读取palettes
    private func restoreFromUserDefaults() {
        // [Palette].self和Array<Palette>.self是一样的
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData)
        {
            palettes = decodedPalettes
        }

        // 放弃使用的策略,转为用Codable来把数据变成Json存储
        // // 由于默认时palettesAsPropertyList是Any类型,所以使用as保证符合swift的规范
        // if let palettesAsPropertyList = UserDefaults.standard.array(forKey: userDefaultsKey) as? [[String]] {
        //     // 读取(解包)时需要把PropertyList转换成palettes结构
        //     for paletteAsArray in palettesAsPropertyList {
        //         // 如果上面的[$0.name, $0.emojis, String($0.id)]改变了,这里也要跟着改,而且使用了大量魔法数字
        //         if paletteAsArray.count == 3, let id = Int(paletteAsArray[2]), !palettes.contains(where: { $0.id == id }) {
        //             let palette = Palette(name: paletteAsArray[0], emojis: paletteAsArray[1], id: id)
        //             palettes.append(palette)
        //         }
        //     }
        // }
    }

    init(named name: String) {
        self.name = name
        restoreFromUserDefaults() // 尝试从UserDefaults中恢复数据
        // 如果没有palette,就添加一些默认的
        if palettes.isEmpty {
            print("using built-in palettes")
            insertPalette(named: "Vehicles", emojis: "🚙🚗🚘🚕🚖🏎🚚🛻🚛🚐🚓🚔🚑🚒🚀✈️🛫🛬🛩🚁🛸🚲🏍🛶⛵️🚤🛥🛳⛴🚢🚂🚝🚅🚆🚊🚉🚇🛺🚜")
            insertPalette(named: "Sports", emojis: "🏈⚾️🏀⚽️🎾🏐🥏🏓⛳️🥅🥌🏂⛷🎳")
            insertPalette(named: "Music", emojis: "🎼🎤🎹🪘🥁🎺🪗🪕🎻")
            insertPalette(named: "Animals", emojis: "🐥🐣🐂🐄🐎🐖🐏🐑🦙🐐🐓🐁🐀🐒🦆🦅🦉🦇🐢🐍🦎🦖🦕🐅🐆🦓🦍🦧🦣🐘🦛🦏🐪🐫🦒🦘🦬🐃🦙🐐🦌🐕🐩🦮🐈🦤🦢🦩🕊🦝🦨🦡🦫🦦🦥🐿🦔")
            insertPalette(named: "Animal Faces", emojis: "🐵🙈🙊🙉🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨🐯🦁🐮🐷🐸🐲")
            insertPalette(named: "Flora", emojis: "🌲🌴🌿☘️🍀🍁🍄🌾💐🌷🌹🥀🌺🌸🌼🌻")
            insertPalette(named: "Weather", emojis: "☀️🌤⛅️🌥☁️🌦🌧⛈🌩🌨❄️💨☔️💧💦🌊☂️🌫🌪")
            insertPalette(named: "COVID", emojis: "💉🦠😷🤧🤒")
            insertPalette(named: "Faces", emojis: "😀😃😄😁😆😅😂🤣🥲☺️😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳😏😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😤😠😡🤯😳🥶😥😓🤗🤔🤭🤫🤥😬🙄😯😧🥱😴🤮😷🤧🤒🤠")
        } else {
            print("successfully loaded palettes from UserDefaults: \(palettes)")
        }
    }

    // MARK: - Intent

    func palette(at index: Int) -> Palette {
        // 保证请求越界的时候给出一个在范围内的调色板(palettes)
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }

    @discardableResult
    func removePalette(at index: Int) -> Int {
        // 只剩一个palette时,不允许删除
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }

    // 用于新增一个palette(可以保证有唯一id)
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        palettes.insert(palette, at: safeIndex)
    }
}
