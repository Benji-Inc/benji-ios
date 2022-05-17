//
//  MediaViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lightbox
import Lottie

class MediaViewController: LightboxController, Dismissable, TransitionableViewController {

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
    
    var shareImageView = UIImageView(image: UIImage(systemName: "square.and.arrow.up"))
    var shareButton = ThemeButton()
    
    init(with items: [MediaItem],
         startingItem: MediaItem?,
         message: Messageable) {
        
        let images: [LightboxImage]
        images = items.compactMap({ item in
            guard let url = item.url else { return nil }
            switch item.type {
            case .photo:
                return LightboxImage(imageURL: url, text: message.kind.text)
            case .video:
                guard let imageURL = item.previewURL else { return nil }
                return LightboxImage(imageURL: imageURL, text: message.kind.text, videoURL: item.url)
            }
        })

        var startIndex: Int = 0
        if let start = startingItem {
            for (index, item) in items.enumerated() {
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
        
        let animationView = AnimationView.with(animation: .loading)

        LightboxConfig.makeLoadingIndicator = { 
            animationView
        }

        animationView.loopMode = .loop
        animationView.play()
        animationView.squaredSize = 18

        super.init(images: images, startIndex: startIndex)
        // Create an instance of LightboxController.
        self.headerView.closeButton.tintColor = ThemeColor.white.color
        self.headerView.closeButton.imageView?.contentMode = .scaleAspectFit

        // Use dynamic background.
        self.dynamicBackground = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.headerView.addSubview(self.shareImageView)
        self.shareImageView.tintColor = ThemeColor.white.color
        self.shareImageView.contentMode = .scaleAspectFit
        
        self.headerView.addSubview(self.shareButton)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.shareImageView.size = self.headerView.deleteButton.size
        self.shareImageView.left = 12
        self.shareImageView.top = self.view.safeAreaInsets.top - 26
        self.shareButton.frame = self.shareImageView.frame
    }
}
