//
//  HomeCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


class HomeCoordinator: PresentableCoordinator<Void>, DeepLinkHandler {

    lazy var homeVC = HomeViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.homeVC
    }
    
    override func start() {
        super.start()
        
    }
    
    func handle(deepLink: DeepLinkable) {
        
    }
}
