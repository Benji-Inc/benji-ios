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
        ChatClientManager.shared.channelsUpdate.producer.on(value:  { [weak self] (update) in
            guard let `self` = self else { return }
            
            guard let channelsUpdate = update else { return }
            
            switch channelsUpdate.status {
            case .added:
                guard channelsUpdate.channel.isOwnedByMe || channelsUpdate.channel.status == .joined else { return }
                
                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                self.collectionViewManager.insert(item: displayable, at: 0)
            case .changed:
                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                self.collectionViewManager.update(item: displayable)
            case .deleted:
                let displayable = DisplayableChannel(channelType: .channel(channelsUpdate.channel))
                self.collectionViewManager.delete(item: displayable)
            }
        }).start()

        ChannelSupplier.shared.$isSynced.mainSink { [weak self] (isSynced) in
            guard let `self` = self, isSynced else { return }
            self.collectionViewManager.loadAllChannels()
        }.store(in: &self.cancellables)

        ChatClientManager.shared.memberUpdate.producer.on(value:  { [weak self] (update) in
            guard let `self` = self else { return }
            
            guard let memberUpdate = update else { return }
            
            switch memberUpdate.status {
            case .joined:
                if memberUpdate.member.identity == User.current()?.objectId {
                    self.collectionViewManager.insert(item: DisplayableChannel(channelType: .channel(memberUpdate.channel)), at: 0)
                } else {
                    self.collectionViewManager.update(item: DisplayableChannel(channelType: .channel(memberUpdate.channel)))
                }
            case .left:
                if memberUpdate.member.identity == User.current()?.objectId {
                    self.collectionViewManager.delete(item: DisplayableChannel(channelType: .channel(memberUpdate.channel)))
                } else {
                    self.collectionViewManager.update(item: DisplayableChannel(channelType: .channel(memberUpdate.channel)))
                }
            case .changed:
                self.collectionViewManager.update(item: DisplayableChannel(channelType: .channel(memberUpdate.channel)))
            default:
                break
            }
        })
        .start()
    }
}
