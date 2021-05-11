//
//  Postable.swift
//  Ours
//
//  Created by Benji Dodgson on 2/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TwilioChatClient

protocol Postable {
    var author: User? { get set }
    var body: String? { get set }
    var priority: Int { get set }
    var triggerDate: Date? { get set }
    var expirationDate: Date? { get set }
    var type: PostType { get set }
    var file: PFFileObject? { get set }
    var attributes: [String: Any]? { get set }
    var duration: Int { get set }
    var pixelSize: CGSize { get }
    var isLocked: Bool { get }
}

extension Postable {

    var channel: TCHChannel? {
        guard let sid = self.attributes?["channelSid"] as? String,
              let displayable = ChannelSupplier.shared.getChannel(withSID: sid),
              case ChannelType.channel(let channel) = displayable.channelType else { return nil }
        return channel
    }

    var numberOfUnread: Int? {
        return self.attributes?["numberOfUnread"] as? Int
    }

    var connection: Connection? {
        return self.attributes?["connection"] as? Connection
    }

    var reservation: Reservation? {
        return self.attributes?["reservation"] as? Reservation
    }

    var pixelSize: CGSize {
        guard let width = self.attributes?["pixelWidth"] as? Int,
              let height = self.attributes?["pixelHeight"] as? Int else { return .zero }
        return CGSize(width: width, height: height)
    }

    var isLocked: Bool {
        if self.author == User.current() {
            return false
        }

        switch RitualManager.shared.state {
        case .feedAvailable:
            return false
        default:
            if let trigger = self.triggerDate,
               let currentTrigger = RitualManager.shared.currentTriggerDate,
               trigger.isSameDateOrInFuture(for: currentTrigger) {
                return true
            } else {
                return false
            }
        }
    }
}
