//
//  ChannelsViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

protocol ChannelsViewControllerDelegate: class {
    func channelsView(_ controller: ChannelsViewController, didSelect channelType: ChannelType)
    func channelsView(_ controller: ChannelsViewController, didSelect reservation: Reservation)
}

class ChannelsViewController: CollectionViewController<ChannelCell, ChannelsCollectionViewManager> {

    weak var delegate: ChannelsViewControllerDelegate?

    init() {
        let collectionView = ChannelsCollectionView()
        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.allowMultipleSelection = true

        self.collectionViewManager.onSelectedItem.signal.observeValues { (selectedItem) in
            guard let item = selectedItem else { return }
            self.delegate?.channelsView(self, didSelect: item.item.channelType)
        }

        self.collectionViewManager.didSelectReservation = { [unowned self] reservation in
            self.delegate?.channelsView(self, didSelect: reservation)
        }

        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }
}
