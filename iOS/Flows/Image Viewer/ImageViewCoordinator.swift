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

class ImageViewCoordinator: PresentableCoordinator<Void> {

    let imageURLs: [URL]
    let startURL: URL?
    let body: String
    
    let animationView = AnimationView.with(animation: .loading)

    lazy var imageViewController: ImageViewController = {
        let images: [LightboxImage]
        images = self.imageURLs.map { imageURL in
            return LightboxImage(imageURL: imageURL, text: self.body)
        }

        var startIndex: Int = 0
        if let startURL = self.startURL,
            let startURLIndex = self.imageURLs.firstIndex(of: startURL) {
            startIndex = startURLIndex
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

    init(imageURLs: [URL],
         startURL: URL?,
         body: String,
         router: Router,
         deepLink: DeepLinkable?) {

        self.imageURLs = imageURLs
        self.startURL = startURL
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

    var fromVCDismissalType: TransitionType {
        return .crossDissolve
    }
    
    var toVCPresentationType: TransitionType {
        return .crossDissolve
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
