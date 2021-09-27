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

protocol ArchiveViewControllerDelegate: AnyObject {
    func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType)
}

class ArchiveViewController: DiffableCollectionViewController<ArchiveCollectionViewDataSource.SectionType, ArchiveCollectionViewDataSource.ItemType, ArchiveCollectionViewDataSource> {

    weak var delegate: ArchiveViewControllerDelegate?

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    // MARK: - UI

    private(set) var channelListController: ChatChannelListController?

    lazy var segmentedControl: UISegmentedControl = {
        let actions: [UIAction] = ArchiveScope.allCases.map { scope in
            return UIAction.init(title: localized(scope.title)) { action in
                Task {
                   await self.loadData()
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

        self.view.addSubview(self.segmentedControl)
        self.segmentedControl.selectedSegmentIndex = 0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.segmentedControl.width = self.view.width - Theme.contentOffset.doubled
        self.segmentedControl.centerOnX()
        self.segmentedControl.height = 44
        self.segmentedControl.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    // MARK: Data Loading

    override func retrieveDataForSnapshot() async -> [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] {

        guard let query = ArchiveScope(rawValue: self.segmentedControl.selectedSegmentIndex)?.query else { return [:] }

        self.channelListController = try? await ChatClient.shared.queryChannels(query: query)

        guard let channels = self.channelListController?.channels else { return [:] }

        var data: [ArchiveCollectionViewDataSource.SectionType : [ArchiveCollectionViewDataSource.ItemType]] = [:]

        data[.conversations] = channels.map { conversation in
            return .conversation(conversation)
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
}
