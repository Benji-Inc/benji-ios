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
                self.collectionViewManager.delete(items: [displayable])
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }
            guard let memberUpdate = update else { return }

            let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))

            switch memberUpdate.status {
            case .joined:
                if memberUpdate.member.identity == User.current()?.objectId {
                    if let first = self.collectionViewManager.getItem(for: .channels, index: 0) {
                        self.collectionViewManager.insert(items: [displayable], before: first)
                    } else {
                        self.collectionViewManager.append(items: [displayable], to: .channels)
                    }
                } else {
                    self.collectionViewManager.reload(items: [displayable])
                }
            case .left:
                if memberUpdate.member.identity == User.current()?.objectId {
                    self.collectionViewManager.delete(items: [displayable])
                } else {
                    self.collectionViewManager.reload(items: [displayable])
                }
            case .changed:
                self.collectionViewManager.reload(items: [displayable])
            default:
                break
            }
        }.store(in: &self.cancellables)
    }
}
