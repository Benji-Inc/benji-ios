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
    var didSelectShare: CompletionOptional = nil
    
    
    private let messageFooterView = BaseView()
    private let closeImageView = UIImageView(image: UIImage(systemName: "xmark"))
    let closeButton = ThemeButton()
    private let menuImageView = UIImageView(image: UIImage(systemName: "ellipsis"))
    let menuButton = ThemeButton()
    private let messageSummaryView = MessageSummaryView()
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor,
                                                                    ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    let message: Messageable
    
    init(with items: [MediaItem],
         startingItem: MediaItem?,
         message: Messageable) {
        
        self.message = message
        
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
        
        let animationView = AnimationView.with(animation: .loading)

        LightboxConfig.CloseButton.text = ""
        LightboxConfig.makeLoadingIndicator = { 
            animationView
        }

        animationView.loopMode = .loop
        animationView.play()
        animationView.squaredSize = 18

        super.init(images: images, startIndex: startIndex)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.headerView.closeButton.isEnabled = false
        
        self.closeButton.didSelect { [unowned self] in
            self.dismissalDelegate?.lightboxControllerWillDismiss(self)
        }
        
        // Use dynamic background.
        self.dynamicBackground = true
        
        self.footerView.isVisible = false
        self.view.insertSubview(self.messageFooterView, aboveSubview: self.footerView)
        
        self.messageFooterView.addSubview(self.bottomGradientView)
        
        self.headerView.addSubview(self.menuImageView)
        self.menuImageView.tintColor = ThemeColor.white.color
        self.menuImageView.contentMode = .scaleAspectFit
        
        self.headerView.addSubview(self.closeImageView)
        self.closeImageView.tintColor = ThemeColor.white.color
        self.closeImageView.contentMode = .scaleAspectFit
        
        self.headerView.addSubview(self.closeButton)

        self.headerView.addSubview(self.menuButton)
        self.menuButton.showsMenuAsPrimaryAction = true
        self.menuButton.menu = self.buildMenu()
        
        self.messageFooterView.addSubview(self.messageSummaryView)
        self.messageSummaryView.configure(for: self.message)
        self.messageSummaryView.lineDotView.isVisible = false
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
        
        self.messageFooterView.expandToSuperviewWidth()
        self.messageFooterView.height = MessageFooterView.height + self.view.safeAreaInsets.bottom
        self.messageFooterView.centerOnX()
        self.messageFooterView.pin(.bottom)
        
        self.bottomGradientView.expandToSuperviewSize()
        
        self.menuImageView.squaredSize = 22
        self.menuImageView.pin(.right, offset: .xtraLong)
        self.menuImageView.pin(.top)
        
        self.menuButton.squaredSize = 22
        self.menuButton.center = self.menuImageView.center
        
        self.closeImageView.squaredSize = 22
        self.closeImageView.pin(.left, offset: .xtraLong)
        self.closeImageView.pin(.top)
        
        self.closeButton.squaredSize = 44
        self.closeButton.center = self.closeImageView.center
        
        self.messageSummaryView.width = Theme.getPaddedWidth(with: self.messageFooterView.width)
        self.messageSummaryView.height = self.messageFooterView.height - self.view.safeAreaInsets.bottom
        self.messageSummaryView.centerOnX()
        self.messageSummaryView.pin(.top)
    }
    
    private func buildMenu() -> UIMenu {
        
        let share = UIAction(title: "Share",
                              image: UIImage(systemName: "square.and.arrow.up"),
                              attributes: []) { [unowned self] action in
            self.didSelectShare?()
        }

        return UIMenu.init(title: "Menu",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: [share])
    }
}
