//
//  ChannelsCollectionViewManager.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

class ChannelsCollectionViewManager: CollectionViewManager<ChannelsCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case channels = 0
        case reservations = 1
    }

    private(set) var reservations: [Reservation] = []

    private let channelConfig = ManageableCellRegistration<ChannelCell>().cellProvider
    private let reservationConfig = ManageableCellRegistration<ReservationCell>().cellProvider

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

        listConfig.backgroundColor = .clear
        listConfig.showsSeparators = false
        listConfig.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let `self` = self,
                  let section = SectionType(rawValue: indexPath.section), section == .channels,
                  let item = self.getItem(for: indexPath) else { return nil }

            let actionHandler: UIContextualAction.Handler = { action, view, completion in
                guard let channel = item as? DisplayableChannel else { return }
                switch channel.channelType {
                case .system(_):
                    completion(true)
                case .pending(_):
                    completion(true)
                case .channel(let tchChannel):
                    ChannelSupplier.shared.delete(channel: tchChannel)
                        .mainSink { result in
                            switch result {
                            case .success():
                                completion(true)
                            case .error(_):
                                completion(false)
                            }
                        }.store(in: &self.cancellables)
                }
            }

            let action = UIContextualAction(style: .normal, title: "", handler: actionHandler)
            action.image = UIImage(systemName: "trash")
            action.backgroundColor = Color.red.color

            return UISwipeActionsConfiguration(actions: [action])
        }

        let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 110, leading: 0, bottom: 0, trailing: 0)
        return section
    }

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        let combined = Publishers.Zip(
            Reservation.getReservations(for: User.current()!),
            ChannelSupplier.shared.waitForInitialSync()
        )

        combined.mainSink { (result) in
            switch result {
            case .success((let reservations, _)):

                self.reservations = reservations.filter({ (reservation) -> Bool in
                    return !reservation.isClaimed
                })
                self.loadSnapshot()
            case .error(_):
                break
            }
            self.collectionView.animationView.stop()
        }.store(in: &self.cancellables)
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted
        case .reservations:
            return self.reservations
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .channels:
            return self.collectionView.dequeueManageableCell(using: self.channelConfig,
                                                             for: indexPath,
                                                             item: item as? DisplayableChannel)
        case .reservations:
            let cell = self.collectionView.dequeueManageableCell(using: self.reservationConfig,
                                                                 for: indexPath,
                                                                 item: item as? Reservation)
            cell?.button.didSelect { [unowned self] in
                self.select(indexPath: indexPath)
            }

            return cell
        }
    }

    // MARK: Menu overrides

    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {

        guard let channel = ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row],
              let cell = collectionView.cellForItem(at: indexPath) as? ChannelCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ChannelPreviewViewController(with: channel, size: cell.size)
        }, actionProvider: { suggestedActions in
            if channel.isFromCurrentUser {
                return self.makeCurrentUsertMenu(for: channel, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: channel, at: indexPath)
            }
        })
    }

//    func createLayout() -> UICollectionViewCompositionalLayout {
//
//
//        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)
//        return layout
//    }
}
