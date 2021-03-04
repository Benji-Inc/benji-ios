//
//  ChannelsViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 10/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension ChannelsViewController {

    func subscribeToUpdates() {
        
        ChannelSupplier.shared.$channelsUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }
            guard let channelsUpdate = update else { return }

            switch channelsUpdate.status {
            case .added:
                guard channelsUpdate.channel.isOwnedByMe || channelsUpdate.channel.status == .joined else { return }
                self.collectionViewManager.updateUI(animate: true)
            case .changed:
                self.collectionViewManager.updateUI(animate: true)
            case .deleted:
                self.collectionViewManager.updateUI(animate: true)
            }
        }.store(in: &self.cancellables)
    }
}
