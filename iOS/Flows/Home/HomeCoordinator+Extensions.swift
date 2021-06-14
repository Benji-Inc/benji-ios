//
//  HomeCoordinator+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension HomeCoordinator: ToastSchedulerDelegate {

    func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        if let link = deeplink {
            self.handle(deeplink: link)
        }
    }
}
