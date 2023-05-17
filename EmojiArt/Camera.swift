//
//  Camera.swift
//  EmojiArt
//
//  Created by huhu on 2023/5/17.
//

import SwiftUI

struct Camera: UIViewControllerRepresentable {
    // 这个协议是用来将UIKit的控制器嵌入到SwiftUI中的,这将会是一个View(也就是如何把控制器这种UIKit的东西放到swiftUI中使用的方法)
    typealias UIViewControllerType = UIImagePickerController // 表示什么UIViewControllerType你想要Represent

    var handlePickedImage: (UIImage?) -> Void // 当相机拍摄到照片时，会调用这个闭包

    static var isAvailable: Bool { // 判断相机是否可用(比如模拟器就不可用)
        // 这个UIImagePickerController就是MVC中的控制器,包含了相机的所有功能(UI Bundle)
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController() // 创建一个UIImagePickerController
        // 定制相机功能
        picker.sourceType = .camera // 设置为相机
        picker.allowsEditing = true // 允许编辑(可以zoom in/out)
        // 设置代理(由makeCoordinator创建并传入),它是得到callback的唯一方法(比如拍摄成功,或者取消拍摄),之所以要设置代理,是因为如果这是swiftUI这里会是闭包,而UIKit中是代理来接收回调
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // swiftUI中,视图一直更改,不过由于相机不会一直更改,所以这里不需要做任何事情
    }

    // 因为UIKit是面向类的,所以这里必须是类,另外必须继承自NSObject,因为UIImagePickerControllerDelegate, UINavigationControllerDelegate(只在这里需要实现)都是NSObjectProtocol
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        // Coordinator会从UIImagePickerControllerDelegate接收回调,然后将其转换为handlePickedImage闭包来与SwiftUI交互
        var handlePickedImage: (UIImage?) -> Void

        // 由于是类,所以必须init handlePickedImage
        init(handlePickedImage: @escaping (UIImage?) -> Void) {
            self.handlePickedImage = handlePickedImage
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil) // 如果用户取消拍摄,则传入nil
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // 如果用户拍摄了照片,则传入照片

            handlePickedImage((info[.editedImage] ?? info[.originalImage]) as? UIImage) // 由于使用了Any,需要用as限定类型
        }
    }
}
