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
    
    lazy var mediaViewController = MediaViewController(with: self.items,
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
        
        self.mediaViewController.shareButton.didSelect { [unowned self] in
            
            Task {

                var itemsToShare: [Any] = []
                let configuration = URLSessionConfiguration.default
                configuration.requestCachePolicy = .returnCacheDataElseLoad
                let session = URLSession(configuration: configuration)

                await self.items.asyncForEach { item in
                    switch item.type {
                    case .photo:
                        if let url = item.url,
                           let data: Data = try? await session.dataTask(with: url).0,
                           let image = UIImage(data: data) {
                            itemsToShare.append(image)
                        }
                    case .video:
                        if let url = item.url {
                            itemsToShare.append(url)
                        }
                    }
                }

                self.didTapShare(items: itemsToShare)
            }
        }
    }
    
    private func didTapShare(items: [Any]) {
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        activityViewController.
        
        // present the view controller
        self.router.topmostViewController.present(activityViewController, animated: true)
    }
}
