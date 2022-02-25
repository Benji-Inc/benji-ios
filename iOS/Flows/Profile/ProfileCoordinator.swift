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
        
        if let user = self.avatar as? User, user.isCurrentUser {
            self.profileVC.header.avatarView.didSelect { [unowned self] in
                self.presentProfilePicture()
            }
        }
    }
    
    func presentProfilePicture() {
        let vc = ModalPhotoViewController()

        
        vc.onDidComplete = { [unowned vc = vc] _ in
            vc.dismiss(animated: true, completion: nil)
        }

        self.router.present(vc, source: self.profileVC)
    }
}
