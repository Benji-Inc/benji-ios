//
//  ArchiveViewController.swift
//  ArchiveViewController
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import TMROLocalization
import Intents

protocol ArchiveViewControllerDelegate: AnyObject {
    func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType)
}

class ArchiveViewController: DiffableCollectionViewController<ArchiveCollectionViewDataSource.SectionType, ArchiveCollectionViewDataSource.ItemType, ArchiveCollectionViewDataSource> {

    weak var delegate: ArchiveViewControllerDelegate?

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    // MARK: - UI

    #warning("Remove after Beta")
    let addButton = Button()

    private(set) var channelListController: ChatChannelListController?

    lazy var segmentedControl: UISegmentedControl = {
        let actions: [UIAction] = ArchiveScope.allCases.map { scope in
            return UIAction.init(title: localized(scope.title)) { action in
                Task {
                    await self.loadData()
                    self.subscribeToUpdates()
                }.add(to: self.taskPool)
            }
        }

        let control = UISegmentedControl.init(frame: .zero, actions: actions)
        control.backgroundColor = Color.background2.color.withAlphaComponent(0.8)
        return control
    }()

    init() {
        super.init(with: CollectionView(layout: ArchiveCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)

        #warning("Add segmentcontrol back in when Beta is complete.")
       // self.view.addSubview(self.segmentedControl)
        self.segmentedControl.selectedSegmentIndex = 0

        self.view.addSubview(self.addButton)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))


        #warning("Move these requests to more appropriate place")
        /// Request authorization to check Focus Status
        INFocusStatusCenter.default.requestAuthorization { status in
            /// Provides a INFocusStatusAuthorizationStatus
        }

        UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
    }

    override func viewWasPresented() {

        guard let query = ArchiveScope(rawValue: self.segmentedControl.selectedSegmentIndex)?.query else { return }

        Task {
            self.channelListController = try? await ChatClient.shared.queryChannels(query: query)
            await self.loadData()
            self.subscribeToUpdates()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.segmentedControl.width = self.view.width - Theme.contentOffset.doubled
        self.segmentedControl.centerOnX()
        self.segmentedControl.height = 44
        self.segmentedControl.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.centerOnX()
        self.addButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    // MARK: Data Loading

    override func getAllSections() -> [ArchiveCollectionViewDataSource.SectionType] {
        return ArchiveCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] {

        guard let channels = self.channelListController?.channels else { return [:] }

        var data: [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] = [:]

        data[.conversations] = channels.map { conversation in
            return .conversation(conversation.cid)
        }

        await NoticeSupplier.shared.loadNotices()

        data[.notices] = NoticeSupplier.shared.notices.map { notice in
            return .notice(notice)
        }

        return data
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)

        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.archiveView(self, didSelect: identifier)
    }

    override func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {

        guard let conversation = self.channelListController?.channels[indexPath.row],
              let cell = collectionView.cellForItem(at: indexPath) as? ConversationCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ConversationPreviewViewController(with: conversation, size: cell.size)
        }, actionProvider: { suggestedActions in
            if conversation.isOwnedByMe {
                return self.makeCurrentUserMenu(for: conversation, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: conversation, at: indexPath)
            }
        })
    }

    func subscribeToUpdates() {
        self.channelListController?.channelsChangesPublisher.mainSink(receiveValue: { changes in

            changes.forEach { change in
                switch change {
                case .insert(let conversation, let ip):
                    self.dataSource.insertItems([.conversation(conversation.cid)], in: .conversations, atIndex: ip.row)
                case .update(let conversation, _):
                    self.dataSource.reconfigureItems([.conversation(conversation.cid)])
                case .remove(let conversation, _):
                    self.dataSource.deleteItems([.conversation(conversation.cid)])
                default:
                    break
                }
            }
        }).store(in: &self.cancellables)

        self.dataSource.didUpdateConnection = { [unowned self] in
            self.dataSource.reloadSections([.notices])
        }
    }
}
