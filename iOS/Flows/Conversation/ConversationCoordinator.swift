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
import StreamChat

class ConversationCoordinator: PresentableCoordinator<Void> {

    lazy var conversationVC = ConversationViewController(conversation: self.conversation)
    private lazy var cameraVC = ImagePickerViewController()
    private lazy var imagePickerVC: PHPickerViewController = {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.images, .videos])
        let vc = PHPickerViewController.init(configuration: config)
        return vc
    }()
    private var cancellables = Set<AnyCancellable>()

    var conversation: Conversation?

    init(router: Router,
         deepLink: DeepLinkable?,
         conversation: Conversation?) {

        self.conversation = conversation
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        self.conversationVC.onSelectedThread = { [unowned self] (channelID, messageID) in
            self.presentThread(for: channelID, messageID: messageID)
        }
        return self.conversationVC
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

        self.conversationVC.didTapMoreButton = { [unowned self] in
            self.presentPeoplePicker()
        }
    }

    func presentPeoplePicker() {
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {
                if let controller = result {
                   // self.startConversationFlow(for: controller.channel)
                }
            }
        }
        self.router.present(coordinator, source: self.conversationVC)
    }

    func presentThread(for channelID: ChannelId, messageID: MessageId) {
        let threadVC = ConversationThreadViewController(channelID: channelID, messageID: messageID)
        self.router.present(threadVC, source: self.conversationVC)
    }
}

extension ConversationCoordinator: ConversationDetailViewControllerDelegate {

    func conversationDetailViewControllerDidTapMenu(_ view: ConversationDetailViewController) {
        //Present conversation menu
    }
}

extension ConversationCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                   PHPickerViewControllerDelegate {

    private func presentCamera() {

        let alert = UIAlertController(title: "Coming soon", message: "Taking pictures is currently unavailable.", preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)

        alert.addAction(ok)

        self.conversationVC.present(alert, animated: true, completion: nil)
        //        guard self.router.topmostViewController != self.cameraVC, !self.cameraVC.isBeingPresented else { return }
        //
        //        self.cameraVC.sourceType = .camera
        ////        self.cameraVC.dismissHandlers.append { [unowned self] in
        ////            UIView.animate(withDuration: 0.2) {
        ////                self.conversationVC.messageInputAccessoryView.alpha = 1.0
        ////            }
        ////        }
        //        self.conversationVC.present(self.cameraVC, animated: true, completion: nil)
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
        //        self.conversationVC.messageInputAccessoryView.attachmentView.configure(with: attachment)
        //        self.conversationVC.messageInputAccessoryView.updateInputType()
    }

    private func presentPicker() {
        guard self.router.topmostViewController != self.imagePickerVC, !self.imagePickerVC.isBeingPresented else { return }

        self.imagePickerVC.delegate = self
        self.conversationVC.present(self.imagePickerVC, animated: true, completion: nil)
    }

    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task.onMainActor {
            let identifiers: [String] = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            if let asset = fetchResult.firstObject {
                let attachment = Attachment(asset: asset)
                self.conversationVC.messageInputAccessoryView.attachmentView.configure(with: attachment)
                self.conversationVC.messageInputAccessoryView.updateInputType()
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
