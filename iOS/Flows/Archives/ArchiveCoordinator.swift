//
//  ArchiveCoordinator.swift
//  ArchiveCoordinator
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

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
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            #warning("Replace")
//            if let conversationId = deeplink.customMetadata["conversationId"] as? String,
//               let conversation = ConversationSupplier.shared.getConversation(withSID: conversationId) {
//                self.startConversationFlow(for: conversation.conversationType)
//            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {
//                Task {
//                    do {
//                        let connection = try await Connection.getObject(with: connectionId)
//                        guard let conversationId = connection.conversationId,
//                              let conversation = ConversationSupplier.shared.getConversation(withSID: conversationId) else {
//                                  return
//                              }
//
//                        self.startConversationFlow(for: conversation.conversationType)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
        default:
            break
        }
    }
}

extension ArchiveCoordinator: ArchiveViewControllerDelegate {

    nonisolated func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType) {

        switch item {
        case .conversation(let conversation):
            Task.onMainActor {
                self.startConversationFlow(for: conversation.conversationType)
            }
        }
    }

    func startConversationFlow(for type: ConversationType?) {
        self.removeChild()
        var conversation: DisplayableConversation?
        if let t = type {
            conversation = DisplayableConversation(conversationType: t)
        }
        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversation: conversation)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.archiveVC, animated: true)
    }
}
