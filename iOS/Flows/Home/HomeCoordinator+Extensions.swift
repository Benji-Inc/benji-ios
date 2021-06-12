//
//  HomeCoordinator+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SideMenu

extension HomeCoordinator: SideMenuNavigationControllerDelegate {

    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animate(show: false)
    }

    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
        if let _ = menu.viewControllers.first as? ProfileViewController {
            self.addProfile(shouldPresent: false)
        } else if let _ = menu.viewControllers.first as? ChannelsViewController {
           // self.addChannels(shouldPresent: false)
        }
    }

    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {

    }

    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animate(show: true)
    }

    func addProfile(shouldPresent: Bool = true) {
        self.removeChild()

        self.addChildAndStart(self.profileCoordinator) { (_) in }
        if let left = SideMenuManager.default.leftMenuNavigationController, shouldPresent {
            self.homeVC.present(left, animated: true, completion: nil)
        }
    }
}

extension HomeCoordinator: ToastSchedulerDelegate {

    func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        if let link = deeplink {
            self.handle(deeplink: link)
        }
    }
}
