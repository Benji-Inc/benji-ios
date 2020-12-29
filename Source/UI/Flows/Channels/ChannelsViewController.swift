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

        self.collectionViewManager.$onSelectedItem.mainSink { [weak self] (value) in
            guard let `self` = self, let item = value else { return }
            self.delegate?.channelsView(self, didSelect: item.item.channelType)
        }.store(in: &self.cancellables)

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
        self.reservationButton.pin(.bottom, padding: Theme.contentOffset)
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
                self.updateButton(with: reservations)
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

    private func updateButton(with reservations: [Reservation]) {
        let count = reservations.count
        let claimed = reservations.filter { (reservation) -> Bool in
            return reservation.isClaimed
        }
        let countString = String(count - claimed.count)
        let text = LocalizedString(id: "", arguments: [countString], default: "You have @(count) RSVP's left")
        self.reservationButton.set(style: .normal(color: .purple, text: text))
        self.view.layoutNow()
    }
}
