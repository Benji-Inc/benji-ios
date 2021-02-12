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

extension UICollectionView.CellRegistration

class ChannelsCollectionViewManager: NSObject, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var didSelectConnection: ((Connection, Connection.Status) -> Void)? = nil
    var didSelectReservation: ((Reservation) -> Void)? = nil
    var didSelectChannel: ((DisplayableChannel) -> Void)? = nil

    var cancellables = Set<AnyCancellable>()
    private let collectionView: ChannelsCollectionView

    private(set) var connections: [Connection] = []
    private(set) var reservations: [Reservation] = []

    private var hasLoaded: Bool = false

    private let channelConfig = UICollectionView.CellRegistration<ChannelCell, AnyHashable> { (cell, indexPath, model)  in
        guard let channel = model as? DisplayableChannel else { return }
        cell.configure(with: channel)
    }

    private let reservationConfig = UICollectionView.CellRegistration<ReservationCell, AnyHashable> { (cell, indexPath, model)  in
        guard let reservation = model as? Reservation else { return }
        cell.configure(with: reservation)
    }

    private let connectionConfig = UICollectionView.CellRegistration<ConnectionCell, AnyHashable> { (cell, indexPath, model)  in
        guard let connection = model as? Connection else { return }
        cell.configure(with: connection)
    }

    lazy var dataSource: UICollectionViewDiffableDataSource<SectionType, AnyHashable> = {
        return UICollectionViewDiffableDataSource(collectionView: self.collectionView) { (cv, indexPath, item) -> UICollectionViewCell? in
            guard let type = SectionType.init(rawValue: indexPath.section) else { return nil }
            switch type {
            case .connections:
                guard let connection = self.connections[safe: indexPath.row] else { return nil }
                let cell = cv.dequeueConfiguredReusableCell(using: self.connectionConfig, for: indexPath, item: self.connections[safe: indexPath.row])
                cell.didSelectStatus = { [unowned self] status in
                    self.didSelectConnection?(connection, status)
                }
                return cell
            case .channels:
                let cell = cv.dequeueConfiguredReusableCell(using: self.channelConfig, for: indexPath, item: ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row])
                return cell
            case .reservations:
                guard let reservation = self.reservations[safe: indexPath.row] else { return nil }
                let cell = cv.dequeueConfiguredReusableCell(using: self.reservationConfig, for: indexPath, item: self.reservations[safe: indexPath.row])
                cell.button.didSelect { [unowned self] in
                    self.didSelectReservation?(reservation)
                }
                return cell
            }
        }
    }()

    private(set) var snapshot = NSDiffableDataSourceSnapshot<SectionType, AnyHashable>()

    enum SectionType: Int, CaseIterable {
        case connections = 0
        case channels = 1
        case reservations = 2
    }

    init(with collectionView: ChannelsCollectionView) {
        self.collectionView = collectionView
        super.init()
        self.loadAllItems()
    }

    private func loadAllItems() {

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

    private func loadSnapshot() {
        self.snapshot.appendSections(SectionType.allCases)
        self.snapshot.appendItems(ChannelSupplier.shared.allChannelsSorted, toSection: .channels)
        self.snapshot.appendItems(self.connections, toSection: .connections)
        self.snapshot.appendItems(self.reservations, toSection: .reservations)
        self.dataSource.apply(self.snapshot, animatingDifferences: true)
        self.collectionView.dataSource = self.dataSource
    }

    func collectionView(_ collectionView: UICollectionView,
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let type = SectionType.init(rawValue: indexPath.section) else { return }

        switch type {
        case .connections, .reservations:
            break
        case .channels:
            if let channel = ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row] {
                self.didSelectChannel?(channel)
            }
        }
    }

    // MARK: Menu overrides

    func collectionView(_ collectionView: UICollectionView,
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
