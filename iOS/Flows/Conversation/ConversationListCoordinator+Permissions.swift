//
//  ConversationListCoordinator+Permissions.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

// MARK: - Permissions

extension ConversationListCoordinator {

    @MainActor
    func checkForPermissions() async {
        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            self.presentPermissions()
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.presentPermissions()
        }
    }

    @MainActor
    private func presentPermissions() {
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        
        /// Because of how the Permissions are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
            self.conversationListVC.becomeFirstResponder()
        }
        
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: self.conversationListVC, animated: true)
        }
        
        self.conversationListVC.resignFirstResponder()
        self.router.present(coordinator, source: self.conversationListVC)
    }
}
