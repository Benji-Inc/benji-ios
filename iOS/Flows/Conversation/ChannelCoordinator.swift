//
//  ConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Photos
import PhotosUI
import Combine

class ConversationCoordinator: PresentableCoordinator<Void> {

    lazy var channelVC = ConversationViewController(delegate: self)
    private lazy var cameraVC = ImagePickerViewController()
    private lazy var imagePickerVC: PHPickerViewController = {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos])
        let vc = PHPickerViewController.init(configuration: config)
        return vc
    }()
    private var cancellables = Set<AnyCancellable>()

    init(router: Router,
         deepLink: DeepLinkable?,
         channel: DisplayableConversation?) {

        if let c = channel {
            ConversationSupplier.shared.set(activeConversation: c)
        }

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.channelVC
    }

    override func start() {
        super.start()

        NotificationCenter.default.publisher(for: .didTapPhotoCamera)
            .mainSink { (note) in
                self.presentCamera()
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: .didTapPhotoLibrary)
            .removeDuplicates()
            .mainSink { (note) in
                self.presentPicker()
            }.store(in: &self.cancellables)

        self.cameraVC.delegate = self
    }
}

extension ConversationCoordinator: ConversationDetailViewControllerDelegate {

    func channelDetailViewControllerDidTapMenu(_ view: ConversationDetailViewController) {
        //Present channel menu
    }
}

extension ConversationCoordinator: ConversationViewControllerDelegate {

    func channelView(_ controller: ConversationViewController, didTapShare message: Messageable) {
        var items: [Any] = []
        switch message.kind {
        case .text(let text):
            items = [text]
        case .attributedText(_):
            break
        case .photo(_, _):
            break
        case .video(_, _):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .link(let link):
            items = [link]
        }

        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.present(ac, animated: true, completion: nil)
    }
}

extension ConversationCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {

    private func presentCamera() {

        let alert = UIAlertController(title: "Coming soon", message: "Taking pictures is currently unavailable.", preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)

        alert.addAction(ok)

        self.channelVC.present(alert, animated: true, completion: nil)
//        guard self.router.topmostViewController != self.cameraVC, !self.cameraVC.isBeingPresented else { return }
//
//        self.cameraVC.sourceType = .camera
////        self.cameraVC.dismissHandlers.append { [unowned self] in
////            UIView.animate(withDuration: 0.2) {
////                self.channelVC.messageInputAccessoryView.alpha = 1.0
////            }
////        }
//        self.channelVC.present(self.cameraVC, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // Need to convert UIImage to an Attachment

////        defer {
////            self.cameraVC.dismiss(animated: true, completion: nil)
////        }
//
//        guard let asset = info[.phAsset] as? PHAsset else {
//            print("Image not found!")
//            return
//        }
//
//        let attachment = Attachment(asset: asset)
//        self.channelVC.messageInputAccessoryView.attachmentView.configure(with: attachment)
//        self.channelVC.messageInputAccessoryView.updateInputType()
    }

    private func presentPicker() {
        guard self.router.topmostViewController != self.imagePickerVC, !self.imagePickerVC.isBeingPresented else { return }

        self.imagePickerVC.delegate = self
        self.channelVC.present(self.imagePickerVC, animated: true, completion: nil)
    }

    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task.onMainActor {
            let identifiers: [String] = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            if let asset = fetchResult.firstObject {
                let attachment = Attachment(asset: asset)
                self.channelVC.messageInputAccessoryView.attachmentView.configure(with: attachment)
                self.channelVC.messageInputAccessoryView.updateInputType()
            }

            self.imagePickerVC.dismiss(animated: true, completion: nil)
        }
    }
}

private class ImagePickerViewController: UIImagePickerController, Dismissable {
    var dismissHandlers: [DismissHandler] = []

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
}
