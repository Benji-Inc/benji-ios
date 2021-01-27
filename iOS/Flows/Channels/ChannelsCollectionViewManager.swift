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

    enum SectionType: Int, CaseIterable {
        case channels = 0
        case connections = 1
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
            self.collectionView.reloadSections(IndexSet([0]))
        }.store(in: &self.cancellables)


    }

    func loadAllItems() {

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
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let type = SectionType.init(rawValue: indexPath.section), let cv = collectionView as? ChannelCollectionView else { return UICollectionViewCell () }

        switch type {
        case .channels:
            return self.getChannelCell(for: indexPath, collectionView: cv)
        case .connections:
            return UICollectionViewCell()
        case .reservations:
            return UICollectionViewCell()
        }
    }

    private func getChannelCell(for indexPath: IndexPath, collectionView: ChannelCollectionView) -> ChannelCell {
        guard let channel = ChannelSupplier.shared.allChannelsSorted[safe: indexPath.row] else { return ChannelCell() }
        let cell = collectionView.dequeueReusableCell(ChannelCell.self, for: indexPath)
        cell.configure(with: channel)
        return cell
    }

    private func getConnectionCell(for indexPath: IndexPath, collectionView: ChannelCollectionView) -> ConnectionCell {
        guard let connection = self.connections[safe: indexPath.row] else { return ConnectionCell() }
        let cell = collectionView.dequeueReusableCell(ConnectionCell.self, for: indexPath)
        cell.configure(with: connection)
        return cell
    }

    private func getReservationCell(for indexPath: IndexPath, collectionView: ChannelCollectionView) -> ReservationCell {
        guard let reservation = self.reservations[safe: indexPath.row] else { return ReservationCell() }
        let cell = collectionView.dequeueReusableCell(ReservationCell.self, for: indexPath)
        cell.configure(with: reservation)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: collectionView.width, height: 84)
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
