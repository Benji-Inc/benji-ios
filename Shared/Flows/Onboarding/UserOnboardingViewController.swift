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

    private(set) var nameLabel = Label(font: .mediumThin)
    private(set) var bubbleView = SpeechBubbleView(orientation: .up,
                                                   bubbleColor: Color.gray.color,
                                                   borderColor: Color.gray.color)
    private(set) var textView = OnboardingMessageTextView()


    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)

        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.avatarView)
        self.avatarView.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.bubbleView)
        self.view.addSubview(self.textView)

        self.updateUI()
    }

    func updateUI(animateTyping: Bool = true) {
        self.textView.set(text: self.getMessage())
        self.view.layoutNow()
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

        self.textView.setSize(withWidth: maxWidth)

        self.bubbleView.height = self.textView.height + 20 + self.bubbleView.tailLength
        self.bubbleView.width = self.textView.width + 28
        self.bubbleView.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset.half)
        self.bubbleView.centerOnX()

        self.textView.centerOnX()
        self.textView.match(.top, to: .top, of: self.bubbleView, offset: self.bubbleView.tailLength + 10)

        self.blurView.expandToSuperviewSize()
    }

    // MARK: PUBLIC

    func getMessage() -> Localized {
        return LocalizedString.empty
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
    }

    func set(text: Localized) {
        let textColor: Color = .textColor
        let attributedString = AttributedString(text,
                                                fontType: .small,
                                                color: textColor)

        self.set(attributed: attributedString,
                 alignment: .center,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .white)

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        style.alignment = .center

        self.addTextAttributes([NSAttributedString.Key.paragraphStyle: style])
    }
}
