//
//  NewConversationViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didCreate conversationController: ChatChannelController)
}

// Implement new data source
// Add new item type
// update layout with Connections at the top, and contacts at the bottom

//class PeopleViewController: CollectionViewController<PeopleCollectionViewManager.SectionType, PeopleCollectionViewManager> {
//
//    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
//
//    private let createButton = Button()
//
//    weak var delegate: NewConversationViewControllerDelegate?
//
//    override func getCollectionView() -> CollectionView {
//        return PeopleCollectionView()
//    }
//
//    override func initializeViews() {
//        super.initializeViews()
//
//        self.view.insertSubview(self.blurView, belowSubview: self.collectionViewManager.collectionView)
//
//        self.collectionViewManager.$onSelectedItem.mainSink { _ in
//            self.createButton.isEnabled = self.collectionViewManager.selectedItems.count > 0
//        }.store(in: &self.cancellables)
//
//        self.view.insertSubview(self.createButton, aboveSubview: self.collectionViewManager.collectionView)
//        self.createButton.set(style: .normal(color: .purple, text: "Create"))
//        self.createButton.didSelect { [unowned self] in
//            Task {
//                await self.createConversation()
//            }
//        }
//
//        self.createButton.transform = CGAffineTransform.init(translationX: 0, y: 100)
//
//        self.collectionViewManager.didLoadSnapshot = { [unowned self] in
//            UIView.animate(withDuration: Theme.animationDuration) {
//                self.createButton.transform = .identity
//            }
//        }
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//
//        self.blurView.expandToSuperviewSize()
//
//        self.createButton.setSize(with: self.view.width)
//        self.createButton.pinToSafeArea(.bottom, padding: 0)
//        self.createButton.centerOnX()
//    }
//
//    func createConversation() async {
//
//        let members: [UserId] = self.collectionViewManager.selectedItems.compactMap { item in
//            guard let connection = item as? Connection else { return nil }
//            return connection.nonMeUser?.objectId
//        }
//
//        let memberSet = Set(members)
//
//        let channelId = ChannelId(type: .messaging, id: UUID().uuidString)
//
//        do {
//           let controller = try ChatClient.shared.channelController(createChannelWithId: channelId, name: "", imageURL: nil, team: nil, members: memberSet, isCurrentUserMember: true, messageOrdering: .bottomToTop, invites: [], extraData: [:])
//
//            try await controller.synchronize()
//            self.delegate?.peopleView(self, didCreate: controller)
//        } catch {
//            print(error)
//        }
//    }
//}

class PeopleViewController: BlurredViewController {

    weak var delegate: PeopleViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: PeopleCollectionViewLayout())
    lazy var dataSource = PeopleCollectionViewDataSource(collectionView: self.collectionView)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //self.loadQuery(with: .recents)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    // MARK: Data Loading

    @MainActor
    func loadData(with query: ChannelListQuery) async {

        self.collectionView.animationView.play()

        //let controller = try? await ChatClient.shared.queryChannels(query: query)

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        //self.channelListController = controller

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<PeopleCollectionViewDataSource.SectionType,
                                                                      PeopleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()
                                                                          snapshot.deleteAllItems()

        let allCases = PeopleCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: PeopleCollectionViewDataSource.SectionType)
    -> [PeopleCollectionViewDataSource.ItemType] {

        switch section {
        case .connections:
            return []
        case .contacts:
            return []
        }
    }
}
