//
//  NewConversationViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol NewConversationViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didCreate conversationController: ChatChannelController)
}

class PeopleViewController: CollectionViewController<PeopleCollectionViewManager.SectionType, PeopleCollectionViewManager> {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    private let createButton = Button()

    weak var delegate: NewConversationViewControllerDelegate?

    override func getCollectionView() -> CollectionView {
        return PeopleCollectionView()
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.blurView, belowSubview: self.collectionViewManager.collectionView)

        self.collectionViewManager.$onSelectedItem.mainSink { _ in
            self.createButton.isEnabled = self.collectionViewManager.selectedItems.count > 0
        }.store(in: &self.cancellables)

        self.view.insertSubview(self.createButton, aboveSubview: self.collectionViewManager.collectionView)
        self.createButton.set(style: .normal(color: .purple, text: "Create"))
        self.createButton.didSelect { [unowned self] in
            Task {
                await self.createConversation()
            }
        }

        self.createButton.transform = CGAffineTransform.init(translationX: 0, y: 100)

        self.collectionViewManager.didLoadSnapshot = { [unowned self] in
            UIView.animate(withDuration: Theme.animationDuration) {
                self.createButton.transform = .identity
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.createButton.setSize(with: self.view.width)
        self.createButton.pinToSafeArea(.bottom, padding: 0)
        self.createButton.centerOnX()
    }

    func createConversation() async {

        let members: [UserId] = self.collectionViewManager.selectedItems.compactMap { item in
            guard let connection = item as? Connection else { return nil }
            return connection.nonMeUser?.objectId
        }

        let memberSet = Set(members)

        let channelId = ChannelId(type: .messaging, id: UUID().uuidString)

        do {
           let controller = try ChatClient.shared.channelController(createChannelWithId: channelId, name: "", imageURL: nil, team: nil, members: memberSet, isCurrentUserMember: true, messageOrdering: .bottomToTop, invites: [], extraData: [:])

            try await controller.synchronize()
            self.delegate?.peopleView(self, didCreate: controller)
        } catch {
            print(error)
        }
    }
}
