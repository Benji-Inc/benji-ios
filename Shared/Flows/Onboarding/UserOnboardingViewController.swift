//
//  UserOnboardingViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Lottie
import Localization

class UserOnboardingViewController: ViewController {

    private(set) var avatarView = AvatarView()

    private(set) var nameLabel = ThemeLabel(font: .regular)
    private(set) var messageContent = MessageContentView()

    override func initializeViews() {
        super.initializeViews()

        self.avatarView.isHidden = true 
        self.view.set(backgroundColor: .background)

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
        self.nameLabel.pinToSafeArea(.top, offset: .noOffset)

        let height: CGFloat = self.shouldShowLargeAvatar() ? self.view.width * 0.4 : 60
        self.avatarView.setSize(for: height)
        self.avatarView.centerOnX()
        self.avatarView.match(.top, to: .bottom, of: self.nameLabel, offset: .standard)

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)

        self.messageContent.size = self.messageContent.getSize(for: .collapsed, with: maxWidth)
        self.messageContent.match(.top, to: .bottom, of: self.avatarView, offset: .standard)
        self.messageContent.centerOnX()
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
        self.linkTextAttributes = [.foregroundColor: ThemeColor.lightGray.color, .underlineStyle: 0]
        self.lineSpacing = 2
    }
}
