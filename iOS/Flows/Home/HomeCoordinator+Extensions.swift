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
        
    }

    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {

    }

    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        self.homeVC.animate(show: true)
    }
}

extension HomeCoordinator: ToastSchedulerDelegate {

    func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        if let link = deeplink {
            self.handle(deeplink: link)
        }
    }
}
