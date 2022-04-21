//
//  ChatUser+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 1/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatUser {

    static var currentUserRole: UserRole {
        return ChatClient.shared.currentUserController().currentUser?.userRole ?? .anonymous
    }
}
