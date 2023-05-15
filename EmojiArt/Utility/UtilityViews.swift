//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI

// syntactic sure to be able to pass an optional UIImage to Image
// (normally it would only take a non-optional UIImage)
// 接受可选的UIImage，如果不为空则显示，否则不显示

struct OptionalImage: View {
    var uiImage: UIImage?

    var body: some View {
        if self.uiImage != nil {
            Image(uiImage: self.uiImage!)
        }
    }
}

// syntactic sugar
// lots of times we want a simple button
// with just text or a label or a systemImage
// but we want the action it performs to be animated
// (i.e. withAnimation)
// this just makes it easy to create such a button
// and thus cleans up our code

struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation {
                self.action()
            }
        } label: {
            if self.title != nil && self.systemImage != nil {
                Label(self.title!, systemImage: self.systemImage!)
            } else if self.title != nil {
                Text(self.title!)
            } else if self.systemImage != nil {
                Image(systemName: self.systemImage!)
            }
        }
    }
}

// simple struct to make it easier to show configurable Alerts
// just an Identifiable struct that can create an Alert on demand
// use .alert(item: $alertToShow) { theIdentifiableAlert in ... }
// where alertToShow is a Binding<IdentifiableAlert>?
// then any time you want to show an alert
// just set alertToShow = IdentifiableAlert(id: "my alert") { Alert(title: ...) }
// of course, the string identifier has to be unique for all your different kinds of alerts

struct IdentifiableAlert: Identifiable {
    var id: String
    var alert: () -> Alert

    init(id: String, alert: @escaping () -> Alert) {
        self.id = id
        self.alert = alert
    }

    // L15 convenience init added between L14 and L15
    init(id: String, title: String, message: String) {
        self.id = id
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }

    // L15 convenience init added between L14 and L15
    init(title: String, message: String) {
        id = title + message
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }
}

// a button that does undo (preferred) or redo
// also has a context menu which will display
// the given undo or redo description for each

struct UndoButton: View {
    let undo: String?
    let redo: String?

    @Environment(\.undoManager) var undoManager

    var body: some View {
        let canUndo = self.undoManager?.canUndo ?? false
        let canRedo = self.undoManager?.canRedo ?? false
        if canUndo || canRedo {
            Button {
                if canUndo {
                    self.undoManager?.undo()
                } else {
                    self.undoManager?.redo()
                }
            } label: {
                if canUndo {
                    Image(systemName: "arrow.uturn.backward.circle")
                } else {
                    Image(systemName: "arrow.uturn.forward.circle")
                }
            }
            .contextMenu {
                if canUndo {
                    Button {
                        self.undoManager?.undo()
                    } label: {
                        Label(self.undo ?? "Undo", systemImage: "arrow.uturn.backward")
                    }
                }
                if canRedo {
                    Button {
                        self.undoManager?.redo()
                    } label: {
                        Label(self.redo ?? "Redo", systemImage: "arrow.uturn.forward")
                    }
                }
            }
        }
    }
}

extension UndoManager {
    var optionalUndoMenuItemTitle: String? {
        canUndo ? undoMenuItemTitle : nil // 无法撤回时返回nil
    }

    var optionalRedoMenuItemTitle: String? {
        canRedo ? redoMenuItemTitle : nil
    }
}

extension View {
    @ViewBuilder
    func wrappedInNavigationViewToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss { // 只在iphone上显示关闭按扭
            NavigationStack {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
            // .navigationViewStyle(StackNavigationViewStyle()) // 避免出现横屏时分隔显示(我没有出现这个问题,只是冗余设计,不过已经随着NavigationView废弃了)
        } else {
            self
        }
    }

    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if UIDevice.current.userInterfaceIdiom != .pad, let dismiss = dismiss { // 只在iphone上显示关闭按扭
            toolbar {
                ToolbarItem(placement: .cancellationAction) { // 没使用.navigationBarLeading而是让swiftUI决定放置位置(适用平台更多)
                    Button("Close") { dismiss() } // 使用传入的关闭函数
                }
            }
        } else {
            self
        }
    }
}

extension View {
    // 让它变成generic func，然后来指定这个"dont care"为view,另外不是直接传入content,而是接收一个ViewBuilder闭包，这个闭包返回一个view
    func compactableToolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content: View {
        toolbar {
            content().modifier(CompactableIntoContextMenu()) // content就是传入的ViewBuilder
        }
    }
}

struct CompactableIntoContextMenu: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var compact: Bool { // 是否是紧凑模式
        horizontalSizeClass == .compact
    }

    func body(content: Content) -> some View {
        if compact { // 只在紧凑模式下显示菜单
            Button {
                // do nothing
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .contextMenu {
                content
            }
        } else {
            content
        }
    }
}
