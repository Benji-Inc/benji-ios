//
//  ImageViewCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 3/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lightbox

class ImageViewCoordinator: PresentableCoordinator<Void> {

    let imageURLs: [URL]
    let startURL: URL?

    lazy var imageViewController: ImageViewController = {
        let images: [LightboxImage]
        images = self.imageURLs.map { imageURL in
            return LightboxImage(imageURL: imageURL)
        }

        var startIndex: Int = 0
        if let startURL = self.startURL,
            let startURLIndex = self.imageURLs.firstIndex(of: startURL) {
            startIndex = startURLIndex
        }

        // Create an instance of LightboxController.
        let controller = ImageViewController(images: images, startIndex: startIndex)

        // Use dynamic background.
        controller.dynamicBackground = true

        return controller
    }()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.imageViewController
    }

    init(imageURLs: [URL],
         startURL: URL?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.imageURLs = imageURLs
        self.startURL = startURL

        super.init(router: router, deepLink: deepLink)
    }
}

// MARK: - ImageViewController

class ImageViewController: LightboxController, Dismissable {

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
