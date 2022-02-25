//
//  UserProfileCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileCoordinator: PresentableCoordinator<Void> {
    
    lazy var profileVC = ProfileViewController(with: self.avatar)
    private let avatar: Avatar
    
    init(with avatar: Avatar,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.avatar = avatar
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.profileVC
    }
    
    override func start() {
        super.start()
    }
}
