//
//  ChannelsViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine
import TMROLocalization

protocol ChannelsViewControllerDelegate: AnyObject {
    func channelsView(_ controller: ChannelsViewController, didSelect channelType: ChannelType)
    func channelsView(_ controller: ChannelsViewController, didSelect reservation: Reservation)
}

class ChannelsViewController: CollectionViewController<ChannelsCollectionViewManager.SectionType, ChannelsCollectionViewManager> {

    weak var delegate: ChannelsViewControllerDelegate?

    init() {
        super.init(with: ChannelsCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .connections:
                break
            case .channels:
                if let channel = selection.item as? DisplayableChannel {
                    self.delegate?.channelsView(self, didSelect: channel.channelType)
                }
            case .reservations:
                if let reservation = selection.item as? Reservation {
                    self.didSelect(reservation: reservation)
                }
            }
        }.store(in: &self.cancellables)

        self.collectionViewManager.didSelectConnection = { [unowned self] connection, status in
            self.didSelect(connection: connection, status: status)
        }
    }

    private func didSelect(reservation: Reservation) {
        reservation.prepareMetaData(andUpdate: [])
            .mainSink(receiveValue: { (_) in
                self.delegate?.channelsView(self, didSelect: reservation)
            }, receiveCompletion: { (_) in }).store(in: &self.cancellables)
    }

    private func didSelect(connection: Connection, status: Connection.Status) {

        UpdateConnection(connection: connection, status: status).makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { (result) in
                self.collectionViewManager.snapshot.reloadItems([connection])
                //self.collectionView.reloadSections([ChannelsCollectionViewManager.SectionType.connections.rawValue])
            }.store(in: &self.cancellables)
    }
}
