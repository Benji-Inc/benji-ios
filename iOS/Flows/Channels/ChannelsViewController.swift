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
    func channelsViewControllerDidTapAdd(_ controller: ChannelsViewController)
}

class ChannelsViewController: CollectionViewController<ChannelsCollectionViewManager.SectionType, ChannelsCollectionViewManager> {

    weak var delegate: ChannelsViewControllerDelegate?

    private let addButton = Button()

    private lazy var channelsCollectionView: ChannelsCollectionView = {

        var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

        listConfig.showsSeparators = false
        listConfig.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let `self` = self, let item = self.collectionViewManager.getItem(for: indexPath) else { return nil
            }

            let actionHandler: UIContextualAction.Handler = { action, view, completion in
                //model.isDone = true
                completion(true)
                //self.collectionView.reloadItems(at: [indexPath])
            }

            let action = UIContextualAction(style: .normal, title: "Done!", handler: actionHandler)
            action.image = UIImage(systemName: "checkmark")
            action.backgroundColor = .systemGreen

            return UISwipeActionsConfiguration(actions: [action])
        }

        let listLayout = UICollectionViewCompositionalLayout.list(using: listConfig)
        return ChannelsCollectionView(with: listLayout)
    }()

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.addButton, aboveSubview: self.collectionViewManager.collectionView)
        self.addButton.set(style: .normal(color: .purple, text: "+"))
        self.addButton.didSelect { [unowned self] in
            self.delegate?.channelsViewControllerDidTapAdd(self)
        }

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
    }

    override func getCollectionView() -> CollectionView {
        return self.channelsCollectionView
    }

    private func didSelect(reservation: Reservation) {
        reservation.prepareMetaData(andUpdate: [])
            .mainSink(receiveValue: { (_) in
                self.delegate?.channelsView(self, didSelect: reservation)
            }, receiveCompletion: { (_) in }).store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.addButton.size = CGSize(width: 50, height: 50)
        self.addButton.pin(.right, padding: Theme.contentOffset)
        self.addButton.pin(.bottom, padding: Theme.contentOffset)
    }
}
