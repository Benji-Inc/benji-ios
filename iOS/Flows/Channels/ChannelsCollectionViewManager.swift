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
        case connections = 0
        case channels = 1
        case reservations = 2
    }

    var cancellables = Set<AnyCancellable>()

    private(set) var connections: [Connection] = []
    private(set) var reservations: [Reservation] = []

    private let channelConfig = ManageableCellRegistration<ChannelCell>().cellProvider
    private let reservationConfig = ManageableCellRegistration<ReservationCell>().cellProvider
    private let connectionConfig = ManageableCellRegistration<ConnectionCell>().cellProvider

    override func initialize() {
        super.initialize()

        self.collectionView.animationView.play()

        let combined = Publishers.Zip3(
            GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []),
            Reservation.getReservations(for: User.current()!),
            ChannelSupplier.shared.waitForInitialSync()
        )

        combined.mainSink { (result) in
            switch result {
            case .success((let connections, let reservations, _)):
                self.connections = connections.filter({ (connection) -> Bool in
                    return connection.status == .invited && connection.to == User.current()
                })
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
        case .connections:
            return self.connections
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted
        case .reservations:
            return self.reservations
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .connections:
            let cell = self.collectionView.dequeueManageableCell(using: self.connectionConfig, for: indexPath, item: item as? Connection)
            cell?.didUpdateConnection = { [unowned self] connection in
                self.connections.remove(object: connection)
                self.reload(sections: [.channels, .connections], animate: true)
            }
            return cell
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

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let type = SectionType.init(rawValue: indexPath.section) else { return .zero }

        switch type {
        case .channels:
            return CGSize(width: collectionView.width, height: 84)
        case .connections:
            return CGSize(width: collectionView.width, height: 168)
        case .reservations:
            return CGSize(width: collectionView.width, height: 64)
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
}
