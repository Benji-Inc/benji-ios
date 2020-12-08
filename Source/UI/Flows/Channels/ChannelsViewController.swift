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

    private let reservationButton = Button()
    private var reservation: Reservation?

    init() {
        super.init(with: ChannelsCollectionView())
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

        self.view.insertSubview(self.reservationButton, aboveSubview: self.collectionView)
        self.reservationButton.isHidden = true
        self.getReservations()

        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()

        self.reservationButton.setSize(with: self.view.width)
        self.reservationButton.pin(.bottom)
        self.reservationButton.centerOnX()
    }

    private func getReservations() {
        guard let user = User.current() else { return }

        Reservation.getReservations(for: user)
            .observeValue { [weak self] (reservations) in
                guard let `self` = self else { return }

                self.reservation = reservations.first(where: { (reservation) -> Bool in
                    return !reservation.isClaimed
                })

                self.reservationButton.isHidden = self.reservation.isNil
        }

        self.reservationButton.didSelect { [unowned self] in
            if let reservation = self.reservation {
                self.didSelect(reservation: reservation)
            }
        }
    }

    private func didSelect(reservation: Reservation) {
        reservation.prepareMetaData(andUpdate: [self.reservationButton])
            .observeValue { (_) in
                self.delegate?.channelsView(self, didSelect: reservation)
        }
    }
}
