//
//  RoomCoordinator+Notices.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension RoomCoordinator {
    
    // The primary action
    func handleRightOption(with notice: SystemNotice) {
        switch notice.type {
        case .timeSensitiveMessage, .messageRead:
            guard let cidValue = notice.attributes?["channelId"] as? String,
                  let cid = try? ChannelId(cid: cidValue),
                  let messageId = notice.attributes?["messageId"] as? String else { return }
            self.presentConversation(with: cid, messageId: messageId)
        case .connectionRequest:
            Task {
                guard let connectionId = notice.attributes?["connectionId"] as? String,
                      let connection = PeopleStore.shared.allConnections.first(where: { existing in
                          return existing.objectId == connectionId
                      }), let user = try? await connection.nonMeUser?.retrieveDataIfNeeded() else { return }
                
                do {
                    try await UpdateConnection(connectionId: connectionId, status: .accepted)
                        .makeRequest(andUpdate:[], viewsToIgnore: [])
                                    
                    let text = "Your are now connected to \(user.fullName)."
                    
                    await ToastScheduler.shared.schedule(toastType: .basic(identifier: connectionId,
                                                                     displayable: user,
                                                                     title: "Connection Accepted",
                                                                     description: text,
                                                                     deepLink: nil))
                    
                    if let n = notice.notice {
                        try n.delete()
                        await self.roomVC.reloadNotices()
                    }

                } catch {
                    logError(error)
                }
            }
        case .connectionConfirmed:
            Task {
                if let n = notice.notice {
                    try n.delete()
                    await self.roomVC.reloadNotices()
                }
            }
        case .unreadMessages:
            break // Scroll to unread tab
        case .system:
            break // Delete notice
        }
    }
    
    // The secondary action
    func handleLeftOption(with notice: SystemNotice) {

        switch notice.type {
        case .connectionRequest:
            Task {
                guard let connectionId = notice.attributes?["connectionId"] as? String else { return }
                _ = try await UpdateConnection(connectionId: connectionId, status: .declined)
                    .makeRequest(andUpdate:[], viewsToIgnore: [])
                
                if let n = notice.notice {
                    try n.delete()
                    await self.roomVC.reloadNotices()
                }
            }
        default:
            break
        }
    }
}
