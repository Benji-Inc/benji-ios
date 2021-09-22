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
    private(set) var animationView = AnimationView.with(animation: .arrow)
    private(set) var backButton = Button()
    private(set) var avatarView = AvatarView()
    private var textBubbleView = TextBubbleView()

    let scrollView = UIScrollView()

    override func loadView() {
        self.view = self.scrollView
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
        self.animationView.transform = CGAffineTransform(rotationAngle: halfPi * -1)
        self.view.addSubview(self.backButton)
        self.backButton.set(style: .animation(view: self.animationView))
        self.backButton.didSelect { [unowned self] in
            self.didSelectBackButton()
        }

        self.view.addSubview(self.avatarView)
        self.view.addSubview(self.textBubbleView)

        self.updateUI()
    }

    func updateUI(animateBackButton: Bool = true) {
        self.textBubbleView.set(text: self.getMessage())

        self.animationView.alpha = self.shouldShowBackButton() ? 1.0 : 0.0

        if animateBackButton {
            delay(1.5) {
                self.animationView.play(fromFrame: 0, toFrame: 160, loopMode: nil, completion: nil)
            }
        }

        self.view.layoutNow()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.backButton.size = CGSize(width: 40, height: 40)
        self.backButton.left = Theme.contentOffset - 10
        self.backButton.top = Theme.contentOffset

        self.avatarView.setSize(for: 100)
        self.avatarView.pin(.left, padding: Theme.contentOffset)
        self.avatarView.match(.top, to: .bottom, of: self.backButton)

        let maxWidth = self.view.width - Theme.contentOffset.doubled
        self.textBubbleView.setSize(withWidth: maxWidth)
        self.textBubbleView.pin(.left, padding: Theme.contentOffset)

        self.textBubbleView.match(.top, to: .bottom, of: self.avatarView, offset: 10)

        self.blurView.expandToSuperviewSize()
    }

    // MARK: PUBLIC

    func shouldShowBackButton() -> Bool {
        return true
    }

    func getMessage() -> Localized {
        return LocalizedString.empty
    }

    func didSelectBackButton() { }
}

private class TextBubbleView: TextView {

    override func initializeViews() {
        super.initializeViews()

        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = false

        self.set(backgroundColor: .background2)
    }

    func set(text: Localized) {
        let textColor: Color = .white
        let attributedString = AttributedString(text,
                                                fontType: .smallBold,
                                                color: textColor)

        self.set(attributed: attributedString,
                 alignment: .left,
                 lineCount: 0,
                 lineBreakMode: .byWordWrapping,
                 stringCasing: .unchanged,
                 isEditable: false,
                 linkColor: .teal)

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2

        self.addTextAttributes([NSAttributedString.Key.paragraphStyle: style])
    }
}
