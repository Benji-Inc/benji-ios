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

            let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))

            switch channelsUpdate.status {
            case .added:
                guard channelsUpdate.channel.isOwnedByMe || channelsUpdate.channel.status == .joined else { return }
                self.collectionViewManager.append(items: [displayable], to: .channels)
            case .changed:
                self.collectionViewManager.reload(items: [displayable])
            case .deleted:
                self.collectionViewManager.delete(items: [displayable], section: .channels)
            }
        }.store(in: &self.cancellables)
    }
}
