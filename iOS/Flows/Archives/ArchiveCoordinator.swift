//
//  ArchiveCoordinator.swift
//  ArchiveCoordinator
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ArchiveCoordinator: PresentableCoordinator<Void> {

    private lazy var archiveVC: ArchiveViewController = {
        let vc = ArchiveViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.archiveVC
    }

    override func start() {
        super.start()

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }

        ToastScheduler.shared.delegate = self

        self.archiveVC.addButton.didSelect { [unowned self] in

            //            self.presentPhoto()
            Task {
                await self.createConversation()
            }.add(to: self.archiveVC.taskPool)
        }
    }

    func presentPhoto() {
        let vc = ProfilePhotoViewController()
        self.router.topmostViewController.present(vc, animated: true, completion: nil)
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            if let identifier = deeplink.customMetadata["conversationId"] as? String {
                guard let conversationId = try? ChannelId.init(cid: identifier) else { return }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation

                self.startConversationFlow(for: conversation)
            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {

                guard let connection = ConnectionStore.shared.connections.first { connection in
                    return connection.objectId == connectionId
                }, let identifier = connection.conversationId,
                       let conversationId = try? ChannelId.init(cid: identifier)  else {
                           return
                       }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation

                self.startConversationFlow(for: conversation)
            }
        default:
            break
        }
    }

    #warning("Remove after Beta")
    func createConversation() async {
        let channelId = ChannelId(type: .messaging, id: UUID().uuidString)

        do {
            let controller = try ChatClient.shared.channelController(createChannelWithId: channelId,
                                                                     name: nil,
                                                                     imageURL: nil,
                                                                     team: nil,
                                                                     members: [],
                                                                     isCurrentUserMember: true,
                                                                     messageOrdering: .bottomToTop,
                                                                     invites: [],
                                                                     extraData: [:])

            try await controller.synchronize()
            self.startConversationFlow(for: controller.conversation)
        } catch {
            print(error)
        }
    }
}

extension ArchiveCoordinator: ArchiveViewControllerDelegate {

    nonisolated func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType) {

        Task.onMainActor {
            switch item {
            case .notice(let notice):
                self.handle(notice: notice)
            case .conversation(let conversationID):
                let conversation = ChatClient.shared.channelController(for: conversationID).conversation
                self.startConversationFlow(for: conversation)
            }
        }
    }

    func startConversationFlow(for conversation: Conversation?) {
        self.removeChild()

        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversation: conversation)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                _ = ConversationsManager.shared.activeConversations.popLast()
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.router.topmostViewController, animated: true)
    }

    private func handle(notice: SystemNotice) {
        switch notice.type {
        case .alert:
            if let conversationID = notice.attributes?["conversationId"] as? ChannelId {
                let conversation = ChatClient.shared.channelController(for: conversationID).conversation
                self.startConversationFlow(for: conversation)
            }
        case .connectionRequest:
            break
        case .connectionConfirmed:
            break
        case .messageRead:
            break
        case .system:
            break
        case .rsvps:
            self.startPeopleFlow()
        }
    }

    func startPeopleFlow() {
        self.removeChild()
        let coordinator = PeopleCoordinator(includeConnections: false,
                                            router: self.router,
                                            deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.archiveVC)
    }
}

private class ProfilePhotoViewController: PhotoViewController {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.blurView, at: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
    }
}
