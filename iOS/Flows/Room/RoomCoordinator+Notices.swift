//
//  RoomCoordinator+Notices.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension RoomCoordinator {
    
    // The primary action
    func handleRightOption(with notice: Notice) {
        guard let type = notice.type else { return }
        
        switch type {
        case .timeSensitiveMessage:
            break // Go to message
        case .connectionRequest:
            break // Update connection request to accepted
        case .connectionConfirmed:
            break // Delete notice
        case .messageRead:
            break // Go to message
        case .unreadMessages:
            break // Scroll to unread tab
        case .system:
            break // Delete notice
        }
    }
    
    // The secondary action
    func handleLeftOption(with notice: Notice) {
        guard let type = notice.type else { return }

        switch type {
        case .timeSensitiveMessage:
            break
        case .connectionRequest:
            break
        case .connectionConfirmed:
            break
        case .messageRead:
            break
        case .unreadMessages:
            break
        case .system:
            break
        }
    }
}
