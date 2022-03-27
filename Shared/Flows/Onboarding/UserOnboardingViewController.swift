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
    private(set) var messageBubble = SpeechBubbleView(orientation: .up, bubbleColor: .D1)
    private(set) var textView = OnboardingMessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.personView.isHidden = true 

        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.personView)
        self.personView.didSelect { [unowned self] in
            self.didSelectBackButton()
        }
        
        self.view.addSubview(self.messageBubble)
        self.messageBubble.addSubview(self.textView)
        self.textView.setTextColor(.T3)

        self.updateUI()
    }

    func updateUI(animateTyping: Bool = true) {
        if let text = self.getMessage() {
            self.textView.isHidden = false
            self.messageBubble.isHidden = false
            self.textView.setText(text)
            self.view.layoutNow()
        } else {
            self.textView.isHidden = false
            self.messageBubble.isHidden = false
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
        self.personView.setSize(forHeight: height)
        self.personView.centerOnX()
        self.personView.match(.top, to: .bottom, of: self.nameLabel, offset: .standard)

        let maxWidth = Theme.getPaddedWidth(with: self.view.width)
        self.textView.setSize(withMaxWidth: maxWidth)
        self.textView.centerOnX()
        
        self.messageBubble.size = self.textView.size
        self.messageBubble.size.width += Theme.ContentOffset.long.value.doubled
        self.messageBubble.size.height += Theme.ContentOffset.long.value + Theme.ContentOffset.long.value.doubled
        
        self.messageBubble.match(.top, to: .bottom, of: self.personView, offset: .standard)
        self.messageBubble.centerOnX()
        
        self.textView.pin(.bottom, offset: .long)
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
