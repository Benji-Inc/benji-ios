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
    func channelsViewConrollerDidSelectReservations(_ controller: ChannelsViewController)
    func channelsViewControllerDidTapAdd(_ controller: ChannelsViewController)
}

class ChannelsViewController: CollectionViewController<ChannelsCollectionViewManager.SectionType, ChannelsCollectionViewManager> {

    weak var delegate: ChannelsViewControllerDelegate?

    private let addButton = Button()

    private lazy var channelsCollectionView = ChannelsCollectionView()
    private let gradientView = ChannelsGradientView()

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.insertSubview(self.addButton, aboveSubview: self.collectionViewManager.collectionView)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
        self.addButton.didSelect { [unowned self] in
            self.delegate?.channelsViewControllerDidTapAdd(self)
        }

        self.view.insertSubview(self.gradientView, belowSubview: self.addButton)

        self.collectionViewManager.$onSelectedItem.mainSink { (result) in
            guard let selection = result else { return }
            switch selection.section {
            case .channels:
                if let channel = selection.item as? DisplayableChannel {
                    self.delegate?.channelsView(self, didSelect: channel.channelType)
                }
            }
        }.store(in: &self.cancellables)

        self.collectionViewManager.didSelectReservations = { [unowned self] in
            self.delegate?.channelsViewConrollerDidSelectReservations(self)
        }
    }

    override func getCollectionView() -> CollectionView {
        return self.channelsCollectionView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.pin(.right, padding: Theme.contentOffset)
        self.addButton.pinToSafeArea(.bottom, padding: 0)

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.view.height - self.addButton.top + 20
        self.gradientView.pin(.bottom)
        self.gradientView.pin(.left)
    }
}
