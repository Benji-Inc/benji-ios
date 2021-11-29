//
//  UserOnboardingViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie

class UserOnboardingViewController: ViewController {

    private(set) var blurView = BlurView()
    private(set) var avatarView = AvatarView()

    private(set) var nameLabel = Label(font: .medium, textColor: .textColor)
    private(set) var messageContent = MessageContentView()

    override func initializeViews() {
        super.initializeViews()

        self.avatarView.isHidden = true 
        self.view.set(backgroundColor: .background)

        self.view.addSubview(self.blurView)

        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.avatarView)
        self.avatarView.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.messageContent)
        self.messageContent.configureBackground(color: .white,
                                                brightness: 1.0,
                                                showBubbleTail: true,
                                                tailOrientation: .up)

        self.updateUI()
    }

    func updateUI(animateTyping: Bool = true) {
        if let text = self.getMessage() {
            self.messageContent.isHidden = false
            self.messageContent.textView.setText(text)
            self.view.layoutNow()
        } else {
            self.messageContent.isHidden = true
        }
    }

    func shouldShowLargeAvatar() -> Bool {
        return false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.nameLabel.setSize(withWidth: self.view.width)
        self.nameLabel.centerOnX()
        self.nameLabel.pinToSafeArea(.top, padding: 0)

        let height: CGFloat = self.shouldShowLargeAvatar() ? self.view.width * 0.4 : 60
        self.avatarView.setSize(for: height)
        self.avatarView.centerOnX()
        self.avatarView.match(.top, to: .bottom, of: self.nameLabel, offset: Theme.contentOffset.half)

        let maxWidth = self.view.width - (Theme.contentOffset.doubled.doubled)

        self.messageContent.size = self.messageContent.getSize(with: maxWidth)
        self.messageContent.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset.half)
        self.messageContent.centerOnX()

        self.blurView.expandToSuperviewSize()
    }

    // MARK: PUBLIC

    func getMessage() -> Localized? {
        return nil
    }

    func didSelectBackButton() { }
}

class OnboardingMessageTextView: TextView {

    override func initializeViews() {
        super.initializeViews()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = false
        self.textAlignment = .center
        self.textContainer.lineBreakMode = .byWordWrapping
        self.isEditable = false
        self.linkTextAttributes = [.foregroundColor: Color.lightGray.color, .underlineStyle: 0]
        self.lineSpacing = 2
    }
}
