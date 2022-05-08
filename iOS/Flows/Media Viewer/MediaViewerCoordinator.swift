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

class MediaViewerCoordinator: PresentableCoordinator<Void> {
    
    let items: [MediaItem]
    let startingItem: MediaItem?

    let body: String
    
    let animationView = AnimationView.with(animation: .loading)

    lazy var imageViewController: ImageViewController = {
        let images: [LightboxImage]
        images = self.items.compactMap({ item in
            guard let url = item.url else { return nil }
            switch item.type {
            case .photo:
                return LightboxImage(imageURL: url, text: self.body)
            case .video:
                guard let image = item.image else { return nil }
                return LightboxImage(image: image, text: self.body, videoURL: url)
            }
        })


        var startIndex: Int = 0
        if let start = self.startingItem {
            for (index, item) in self.items.enumerated() {
                if item.url == start.url {
                    startIndex = index
                    break
                }
            }
        }
        
        LightboxConfig.PageIndicator.textAttributes = [.font: FontType.xtraSmall.font,
                                                       .foregroundColor: ThemeColor.white.color.withAlphaComponent(0.2)]
        
        LightboxConfig.InfoLabel.textAttributes = [.font: FontType.small.font,
                                                   .foregroundColor: ThemeColor.white.color]
        
        LightboxConfig.CloseButton.text = ""
        LightboxConfig.CloseButton.image = UIImage(systemName: "xmark")
        LightboxConfig.CloseButton.size = CGSize(width: 20, height: 18)
        
        LightboxConfig.makeLoadingIndicator = { [unowned self] in
            self.animationView
        }
        
        self.animationView.loopMode = .loop
        self.animationView.play()
        self.animationView.squaredSize = 18

        // Create an instance of LightboxController.
        let controller = ImageViewController(images: images, startIndex: startIndex)
        controller.headerView.closeButton.tintColor = ThemeColor.white.color
        controller.headerView.closeButton.imageView?.contentMode = .scaleAspectFit

        // Use dynamic background.
        controller.dynamicBackground = true
        

        return controller
    }()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.imageViewController
    }

    init(items: [MediaItem],
         startingItem: MediaItem?,
         body: String,
         router: Router,
         deepLink: DeepLinkable?) {

        self.items = items
        self.startingItem = startingItem
        self.body = body

        super.init(router: router, deepLink: deepLink)
    }
    
    override func start() {
        super.start()
        
        self.imageViewController.transitioningDelegate = self.router.modalTransitionRouter
    }
}

// MARK: - ImageViewController

class ImageViewController: LightboxController, Dismissable, TransitionableViewController {

    var dismissalType: TransitionType {
        return .crossDissolve
    }
    
    var presentationType: TransitionType {
        return .crossDissolve
    }

    func getFromVCPresentationType(for toVCPresentationType: TransitionType) -> TransitionType {
        return toVCPresentationType
    }

    func getToVCDismissalType(for fromVCDismissalType: TransitionType) -> TransitionType {
        return fromVCDismissalType
    }

    var dismissHandlers: [DismissHandler] = []
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
}
