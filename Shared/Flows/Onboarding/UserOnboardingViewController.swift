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

    private(set) var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private(set) var avatarView = AvatarView()

    private(set) var bubbleView = View()
    private(set) var textBubbleView = UserMessageView()

    let scrollView = UIScrollView()

    override func loadView() {
        self.view = self.scrollView
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)

        self.view.addSubview(self.avatarView)
        self.avatarView.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.bubbleView)

        self.bubbleView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        self.bubbleView.set(backgroundColor: .lightPurple)

        self.bubbleView.addSubview(self.textBubbleView)

        self.updateUI()
    }

    func updateUI(animateTyping: Bool = true) {
        self.textBubbleView.set(text: self.getMessage())
        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.avatarView.setSize(for: 80)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.pin(.top, padding: Theme.contentOffset)

        let maxWidth = self.view.width - (Theme.contentOffset.doubled + Theme.contentOffset + 28)

        self.textBubbleView.setSize(withWidth: maxWidth)

        self.bubbleView.height = self.textBubbleView.height + 20
        self.bubbleView.width = self.textBubbleView.width + 28
        self.bubbleView.match(.top, to: .bottom, of: self.avatarView, offset: 6)
        self.bubbleView.match(.left, to: .left, of: self.avatarView)
        self.bubbleView.roundCorners()

        self.textBubbleView.centerOnXAndY()

        self.blurView.expandToSuperviewSize()
    }

    // MARK: PUBLIC

    func getMessage() -> Localized {
        return LocalizedString.empty
    }

    func didSelectBackButton() { }
}

class UserMessageView: TextView {

    override func initializeViews() {
        super.initializeViews()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = false
    }

    func set(text: Localized) {
        let textColor: Color = .white
        let attributedString = AttributedString(text,
                                                fontType: .regularBold,
                                                color: textColor)

        self.set(attributed: attributedString,
                 alignment: .left,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .white)

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2

        self.addTextAttributes([NSAttributedString.Key.paragraphStyle: style])
    }
}
