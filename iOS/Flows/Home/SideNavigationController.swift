//
//  SideNaviationController.swift
//  Ours
//
//  Created by Benji Dodgson on 3/2/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SideMenu

class SideNavigationController: SideMenuNavigationController {

    init(with rootViewController: UIViewController, width: CGFloat? = nil) {
        var settings = SideMenuSettings()
        if let width = width {
            settings.menuWidth = width
        }
        super.init(rootViewController: rootViewController, settings: settings)

        self.view.set(backgroundColor: .background1)
        self.setNavigationBarHidden(true, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
