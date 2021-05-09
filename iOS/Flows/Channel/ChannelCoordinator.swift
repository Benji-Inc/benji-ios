//
//  ChannelCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/14/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Photos
import Combine

class ChannelCoordinator: PresentableCoordinator<Void> {

    lazy var channelVC = ChannelViewController(delegate: self)
    private lazy var imagePickerVC = ImagePickerViewController()
    private var cancellables = Set<AnyCancellable>()

    init(router: Router,
         deepLink: DeepLinkable?,
         channel: DisplayableChannel?) {

        if let c = channel {
            ChannelSupplier.shared.set(activeChannel: c)
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
                self.presentPicker(for: .camera)
            }.store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: .didTapPhotoLibrary)
            .removeDuplicates()
            .mainSink { (note) in
                self.presentPicker(for: .photoLibrary)
            }.store(in: &self.cancellables)

        self.imagePickerVC.delegate = self
    }
}

extension ChannelCoordinator: ChannelDetailViewControllerDelegate {

    func channelDetailViewControllerDidTapMenu(_ view: ChannelDetailViewController) {
        //Present channel menu
    }
}

extension ChannelCoordinator: ChannelViewControllerDelegate {

    func channelView(_ controller: ChannelViewController, didTapShare message: Messageable) {
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
        }

        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.present(ac, animated: true, completion: nil)
    }
}

extension ChannelCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @objc func didTapPhotoCamera(_ notification: Notification) {
        self.presentPicker(for: .camera)
    }

    @objc func didTapPhotoLibrary(_ notification: Notification) {
        self.presentPicker(for: .photoLibrary)
    }

    private func presentPicker(for type: UIImagePickerController.SourceType) {
        guard self.router.topmostViewController != self.imagePickerVC, !self.imagePickerVC.isBeingPresented else { return }

        self.imagePickerVC.sourceType = type
        self.imagePickerVC.dismissHandlers.append { [unowned self] in
            UIView.animate(withDuration: 0.2) {
                self.channelVC.messageInputAccessoryView.alpha = 1.0
            }
        }
        self.channelVC.present(self.imagePickerVC, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        defer {
            self.imagePickerVC.dismiss(animated: true, completion: nil)
        }

        guard let asset = info[.phAsset] as? PHAsset else {
            print("Image not found!")
            return
        }

        let attachment = Attachment(asset: asset)
        self.channelVC.messageInputAccessoryView.attachmentView.configure(with: attachment)
        self.channelVC.messageInputAccessoryView.updateInputType()
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
