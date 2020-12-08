//
//  Button.swift
//  Benji
//
//  Created by Benji Dodgson on 2/4/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Lottie
import TMROFutures

enum ButtonStyle {
    case rounded(color: Color, text: Localized)
    case normal(color: Color, text: Localized)
    case icon(image: UIImage)
    case animation(view: AnimationView, inset: CGFloat = 8)
}

class Button: UIButton, Statusable {

    let alphaOutAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                  curve: .linear,
                                                  animations: nil)

    let alphaInAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                 curve: .linear,
                                                 animations: nil)

    /// Used to store the initial color of the button to return to from error state
    var defaultColor: Color?

    let animationView = AnimationView(name: "loading")

    var style: ButtonStyle?
    lazy var errorLabel = RegularLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeSubviews() {

        self.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.addSubview(self.errorLabel)
        self.errorLabel.alpha = 0.0
    }

    //Sets text font, color and background color
    func set(style: ButtonStyle, casingType: StringCasing = .uppercase) {
        self.style = style

        switch style {
        case .rounded(let color, let text), .normal(let color, let text):

            self.defaultColor = color

            var localizedString = localized(text)

            localizedString = casingType.format(string: localizedString)

            let normalString = NSMutableAttributedString(string: localizedString)
            normalString.addAttribute(.font, value: FontType.smallBold.font)
            normalString.addAttribute(.kern, value: CGFloat(2))

            let highlightedString = NSMutableAttributedString(string: localizedString)
            highlightedString.addAttribute(.font, value: FontType.smallBold.font)
            highlightedString.addAttribute(.kern, value: CGFloat(2))

            normalString.addAttribute(.foregroundColor, value: color.color)
            highlightedString.addAttribute(.foregroundColor, value: color.color)
            self.setBackground(color: color.color.withAlphaComponent(0.4), forUIControlState: .normal)
            self.setBackground(color: Color.clear.color, forUIControlState: .highlighted)

            // Emojis wont show correctly with attributes
            if localizedString.getEmojiRanges().count > 0 {
                self.setTitle(localizedString, for: .normal)
                self.setTitle(localizedString, for: .highlighted)
            } else {
                self.setAttributedTitle(normalString, for: .normal)
                self.setAttributedTitle(highlightedString, for: .highlighted)
            }

            self.layer.borderColor = color.color.cgColor
            self.layer.borderWidth = 2

        case .icon(let image):
            self.setBackgroundImage(image, for: self.state)
        case .animation(let view, _):
            self.addSubview(view)
            view.expandToSuperviewSize()
            break
        }

        self.layer.cornerRadius = Theme.cornerRadius
        self.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.centerOnXAndY()

        self.errorLabel.height = 20
        self.errorLabel.width = self.width - 40
        self.errorLabel.textAlignment = .center
        self.errorLabel.centerOnXAndY()

        if let style = self.style {
            switch style {
            case .animation(let view, let inset):
                view.frame = CGRect(x: inset,
                                    y: inset,
                                    width: self.width - (inset * 2),
                                    height: self.height - (inset * 2))
            default:
                break
            }
        }
    }

    func setBackground(color: UIColor, forUIControlState state: UIControl.State) {
        self.setBackgroundImage(UIImage.imageWithColor(color: color), for: state)
    }

    func setSize(with width: CGFloat) {
        self.size = CGSize(width: width - (Theme.contentOffset * 2), height: Theme.buttonHeight)
    }

    @discardableResult
    func handleEvent(status: EventStatus) -> Future<Void> {
        switch status {
        case .loading, .initial:
            return self.handleLoadingState()
        case .complete, .saved, .invalid, .custom(_), .valid:
            return self.handleNormalState()
        case .error(let message):
            return self.handleError(message)
        }
    }

//    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        guard self.shouldScale else { return }
//
//        if let touch = touches.first, let view = touch.view, let button = view as? UIButton {
//            button.scaleDown()
//        }
//    }
//
//    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        guard self.shouldScale else { return }
//
//        if let touch = touches.first, let view = touch.view, let button = view as? UIButton {
//            button.scaleUp()
//        }
//    }
//
//    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesCancelled(touches, with: event)
//        guard self.shouldScale else { return }
//
//        if let touch = touches.first, let view = touch.view, let button = view as? UIButton {
//            button.scaleUp()
//        }
//    }
}
