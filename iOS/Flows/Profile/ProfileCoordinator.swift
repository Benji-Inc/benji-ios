//
//  ProfileCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class ProfileCoordinator: PresentableCoordinator<Void> {

    let profileVC: ProfileViewController

    init(router: Router, deepLink: DeepLinkable?, vc: ProfileViewController) {
        self.profileVC = vc
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.profileVC
    }

    override func start() {
        super.start()

        self.profileVC.delegate = self
    }

    private func presentPhoto() {
        let vc = ProfilePhotoViewController(with: self)
        self.router.present(vc, source: self.profileVC)
    }
}

extension ProfileCoordinator: ProfileViewControllerDelegate {

    func profileView(_ controller: ProfileViewController, didSelect item: ProfileItem, for user: User) {
        guard user.isCurrentUser else { return }

        switch item {
        case .ritual:
            break 
        case .picture:
            self.presentPhoto()
        default:
            break 
        }
    }
}

extension ProfileCoordinator: ProfilePhotoViewControllerDelegate {
    func profilePhotoViewControllerDidFinish(_ controller: ProfilePhotoViewController) {
        controller.dismiss(animated: true) {
            guard let user = User.current() else { return }
            self.profileVC.updateItems(with: user)
        }
    }
}
