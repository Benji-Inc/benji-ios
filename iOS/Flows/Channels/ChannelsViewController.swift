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

class ChannelsViewController: ViewController {

    weak var delegate: ChannelsViewControllerDelegate?

    private let collectionView = ChannelsCollectionView()
    lazy var collectionViewManager = ChannelsCollectionViewManager(with: self.collectionView)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)

        self.collectionView.delegate = self.collectionViewManager

        self.collectionViewManager.didSelectChannel = { [unowned self] channel in
            self.delegate?.channelsView(self, didSelect: channel.channelType)
        }

        self.collectionViewManager.didSelectReservation = { [unowned self] reservation in
            self.didSelect(reservation: reservation)
        }

        self.collectionViewManager.didSelectConnection = { [unowned self] connection, status in
            self.didSelect(connection: connection, status: status)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
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
                self.collectionView.reloadSections([ChannelsCollectionViewManager.SectionType.connections.rawValue])
            }.store(in: &self.cancellables)
    }
}
