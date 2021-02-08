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

                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                var updatedSnapshot = self.collectionViewManager.snapshot
                updatedSnapshot.appendItems([displayable])
                self.collectionViewManager.dataSource.apply(updatedSnapshot, animatingDifferences: true)
            case .changed:
                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                var updatedSnapshot = self.collectionViewManager.snapshot
                updatedSnapshot.reloadItems([displayable])
                self.collectionViewManager.dataSource.apply(updatedSnapshot)
            case .deleted:
                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                var updatedSnapshot = self.collectionViewManager.snapshot
                updatedSnapshot.deleteItems([displayable])
                self.collectionViewManager.dataSource.apply(updatedSnapshot)
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }
            guard let memberUpdate = update else { return }
            switch memberUpdate.status {
            case .joined:
                if memberUpdate.member.identity == User.current()?.objectId {
                    let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))
                    var updatedSnapshot = self.collectionViewManager.snapshot

                    if let first = updatedSnapshot.itemIdentifiers(inSection: .channels).first {
                        updatedSnapshot.insertItems([displayable], beforeItem: first)
                    } else {
                        updatedSnapshot.appendItems([displayable], toSection: .channels)
                    }
                    self.collectionViewManager.dataSource.apply(updatedSnapshot)
                } else {
                    let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))
                    var updatedSnapshot = self.collectionViewManager.snapshot
                    updatedSnapshot.reloadItems([displayable])
                    self.collectionViewManager.dataSource.apply(updatedSnapshot)
                }
            case .left:
                if memberUpdate.member.identity == User.current()?.objectId {
                    let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))
                    var updatedSnapshot = self.collectionViewManager.snapshot
                    updatedSnapshot.deleteItems([displayable])
                    self.collectionViewManager.dataSource.apply(updatedSnapshot)
                } else {
                    let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))
                    var updatedSnapshot = self.collectionViewManager.snapshot
                    updatedSnapshot.reloadItems([displayable])
                    self.collectionViewManager.dataSource.apply(updatedSnapshot)
                }
            case .changed:
                let displayable = DisplayableChannel(channelType: .channel(memberUpdate.channel))
                var updatedSnapshot = self.collectionViewManager.snapshot
                updatedSnapshot.reloadItems([displayable])
                self.collectionViewManager.dataSource.apply(updatedSnapshot)
            default:
                break
            }
        }.store(in: &self.cancellables)
    }
}
