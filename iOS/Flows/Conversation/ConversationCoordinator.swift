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

        self.conversationVC.didTapConversationTitle = { [unowned self] in
            guard let conversationController = self.conversationVC.conversationController,
            conversationController.conversation?.membership?.memberRole.rawValue == "owner" else { return }
            self.presentConversationTitleAlert(for: conversationController)
        }
    }

    func presentPeoplePicker() {
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { connections in
            coordinator.toPresentable().dismiss(animated: true)
            guard let conversationController = self.conversationVC.conversationController else { return }
            self.add(connections: connections, to: conversationController)
        }
        self.router.present(coordinator, source: self.conversationVC)
    }

    func add(connections: [Connection], to controller: ChatChannelController) {
        let acceptedConnections = connections.filter { connection in
            return connection.status == .accepted
        }

        let pendingConnections = connections.filter { connection in
            return connection.status == .invited || connection.status == .pending
        }

        for connection in pendingConnections {
            if let conversationID = controller.conversation?.cid.id {
                connection.initialConversations.append(conversationID)
                #warning("Update to use async save function")
                connection.saveEventually()
            }
        }

        if !acceptedConnections.isEmpty {
            let members = acceptedConnections.compactMap { connection in
                return connection.nonMeUser?.objectId
            }
            controller.addMembers(userIds: Set(members)) { error in
                if error.isNil {
                    self.showPeopleAddedToast(for: acceptedConnections)
                }
            }
        }
    }

    private func showPeopleAddedToast(for connections: [Connection]) {
        if connections.count == 1, let first = connections.first?.nonMeUser {
            let text = LocalizedString(id: "", arguments: [first.fullName], default: "@(name) has been added to the conversation.")
            ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: first, title: "\(first.givenName.capitalized) Added", description: text, deepLink: nil))
        } else {
            let text = LocalizedString(id: "", arguments: [String(connections.count)], default: " @(count) people have been added to the conversation.")
            ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: User.current()!, title: "\(String(connections.count)) Added", description: text, deepLink: nil))
        }
    }

    func presentConversationTitleAlert(for controller: ChatChannelController) {

        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "New Name"
        }
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { alert -> Void in
            if let textField = alertController.textFields?.first,
                let text = textField.text,
                !text.isEmpty {

                controller.updateChannel(name: text, imageURL: nil, team: nil) { error in
                    // Do Stuff
                    alertController.dismiss(animated: true, completion: nil)
                }
            }
        })

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)


        self.conversationVC.present(alertController, animated: true, completion: nil)
    }

    func presentThread(for channelID: ChannelId, messageID: MessageId) {
        let threadVC = ConversationThreadViewController(channelID: channelID, messageID: messageID)
        self.router.present(threadVC, source: self.conversationVC)
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
