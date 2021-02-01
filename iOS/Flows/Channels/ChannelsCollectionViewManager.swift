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

class ChannelsCollectionViewManager: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var didSelectReservation: ((Reservation) -> Void)? = nil
    var cancellables = Set<AnyCancellable>()
    private let collectionView: CollectionView

    private(set) var connections: [Connection] = []
    private(set) var reservations: [Reservation] = []

    private var hasLoaded: Bool = false

    private let channelConfig = UICollectionView.CellRegistration<ChannelCell, DisplayableChannel> { (cell, indexPath, model)  in
        cell.configure(with: model)
    }

    private let reservationConfig = UICollectionView.CellRegistration<ReservationCell, Reservation> { (cell, indexPath, model)  in
        cell.configure(with: model)
    }

    private let connectionConfig = UICollectionView.CellRegistration<ConnectionCell, Connection> { (cell, indexPath, model)  in
        cell.configure(with: model)
        cell.didSelectOption = { option in
            print(option)
        }
    }

    enum SectionType: Int, CaseIterable {
        case connections = 0
        case channels = 1
        case reservations = 2
    }

    init(with collectionView: CollectionView) {
        self.collectionView = collectionView
        super.init()
        self.prepare()
    }

    private func prepare() {
        ChannelSupplier.shared.$channelsUpdate.mainSink { (update) in
            guard let _ = update else { return }
            self.collectionView.reloadSections(IndexSet([SectionType.channels.rawValue]))
        }.store(in: &self.cancellables)

        ChannelSupplier.shared.$isSynced.mainSink { (isSynced) in
            guard isSynced, !self.hasLoaded else { return }
            self.loadAllItems()
        }.store(in: &self.cancellables)
    }

    private func loadAllItems() {

        let combined = Publishers.Zip(
            GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []),
            Reservation.getReservations(for: User.current()!)
        )

        combined.mainSink { (result) in
            switch result {
            case .success((let connections, let reservations)):

                self.connections = connections.filter({ (connection) -> Bool in
                    return connection.status == .invited && connection.to == User.current()
                })


                self.reservations = reservations

                self.collectionView.reloadSections(IndexSet([SectionType.connections.rawValue, SectionType.reservations.rawValue]))
            case .error(_):
                break
            }
            self.hasLoaded = true

        }.store(in: &self.cancellables)
    }

    func loadAllChannels() {
//        let cycle = AnimationCycle(inFromPosition: .down,
//                                   outToPosition: .down,
//                                   shouldConcatenate: true,
//                                   scrollToEnd: false)

        //        self.set(newItems: ChannelSupplier.shared.allChannelsSorted,
        //                 animationCycle: cycle,
        //                 completion: nil)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SectionType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let type = SectionType.init(rawValue: section) else { return 0 }
        switch type {
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted.count
        case .connections:
            return self.connections.count
        case .reservations:
            return self.reservations.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let type = SectionType.init(rawValue: indexPath.section) else { return UICollectionViewCell () }

        switch type {
        case .channels:
            return collectionView.dequeueConfiguredReusableCell(using: self.channelConfig, for: indexPath, item: ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row])
        case .connections:
            guard let connection = self.connections[safe: indexPath.row] else { return UICollectionViewCell() }
            return collectionView.dequeueConfiguredReusableCell(using: self.connectionConfig, for: indexPath, item: connection)
        case .reservations:
            guard let reservation = self.reservations[safe: indexPath.row] else { return UICollectionViewCell() }
            return collectionView.dequeueConfiguredReusableCell(using: self.reservationConfig, for: indexPath, item: reservation)
        }
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
            return CGSize(width: collectionView.width, height: 84)
        }
    }

    // MARK: Menu overrides

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {

        return nil 

//        guard let channel = self.getItem(for: indexPath.row),
//              let cell = collectionView.cellForItem(at: indexPath) as? ChannelCell else { return nil }
//
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
//            return ChannelPreviewViewController(with: channel, size: cell.size)
//        }, actionProvider: { suggestedActions in
//            if channel.isFromCurrentUser {
//                return self.makeCurrentUsertMenu(for: channel, at: indexPath)
//            } else {
//                return self.makeNonCurrentUserMenu(for: channel, at: indexPath)
//            }
//        })
    }
}
