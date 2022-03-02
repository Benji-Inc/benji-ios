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

    private(set) var personView = PersonView()

    private(set) var nameLabel = ThemeLabel(font: .regular)
    private(set) var messageContent = MessageContentView()

    override func initializeViews() {
        super.initializeViews()

        self.personView.isHidden = true 

        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.personView)
        self.personView.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.messageContent)
        self.messageContent.configureBackground(color: ThemeColor.D1.color,
                                                textColor: ThemeColor.T3.color,
                                                brightness: 1,
                                                focusAmount: 1,
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

        let height: CGFloat = self.shouldShowLargeAvatar() ? self.view.width * 0.35 : 60
        self.personView.setSize(for: height)
        self.personView.centerOnX()
        self.personView.match(.top, to: .bottom, of: self.nameLabel, offset: .standard)

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)

        self.messageContent.size = self.messageContent.getSize(for: .collapsed, with: maxWidth)
        self.messageContent.match(.top, to: .bottom, of: self.personView, offset: .standard)
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
        self.lineSpacing = 2
    }
}
