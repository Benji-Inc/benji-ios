//
//  ImageViewCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 3/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lightbox
import Lottie

class MediaCoordinator: PresentableCoordinator<Void> {
    
    let items: [MediaItem]
    let startingItem: MediaItem?

    let message: Messageable
    
    lazy var mediaViewController = MediaViewController(items: self.items,
                                                       startingItem: self.startingItem,
                                                       message: self.message)

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.mediaViewController
    }

    init(items: [MediaItem],
         startingItem: MediaItem?,
         message: Messageable,
         router: Router,
         deepLink: DeepLinkable?) {

        self.items = items
        self.startingItem = startingItem
        self.message = message

        super.init(router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.mediaViewController.transitioningDelegate = self.router.modalTransitionRouter
    }
}
