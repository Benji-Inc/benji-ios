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
import Combine

enum ButtonStyle {
    case noborder(image: UIImage, color: Color)
    case rounded(color: Color, text: Localized)
    case normal(color: Color, text: Localized)
    case icon(image: UIImage, color: Color)
    case shadow(image: UIImage, color: Color)
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

    let animationView = AnimationView.with(animation: .loading)

    var style: ButtonStyle?
    lazy var errorLabel = Label(font: .regular)

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
    func set(style: ButtonStyle, casingType: StringCasing = .uppercase, alpha: CGFloat = 0.4) {
        self.style = style

        switch style {
        case .shadow(let image, let color):
            self.defaultColor = color
            self.setImage(image, for: .normal)
            self.tintColor = color.color
            self.showShadow(withOffset: 5)
            
        case .rounded(let color, let text), .normal(let color, let text):
            self.setImage(nil, for: .normal)
            self.defaultColor = color

            var localizedString = localized(text)

            localizedString = casingType.format(string: localizedString)

            let normalString = NSMutableAttributedString(string: localizedString)
            normalString.addAttribute(.font, value: FontType.smallBold.font)
            normalString.addAttribute(.kern, value: CGFloat(2))

            let highlightedString = NSMutableAttributedString(string: localizedString)
            highlightedString.addAttribute(.font, value: FontType.smallBold.font)
            highlightedString.addAttribute(.kern, value: CGFloat(2))

            normalString.addAttribute(.foregroundColor, value: Color.white.color)
            highlightedString.addAttribute(.foregroundColor, value: Color.white.color)
            self.setBackground(color: color.color.withAlphaComponent(alpha), forUIControlState: .normal)
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

        case .icon(let image, let color):
            self.defaultColor = color
            self.setImage(image, for: .normal)
            self.tintColor = color.color
            self.setBackground(color: color.color.withAlphaComponent(alpha), forUIControlState: .normal)
            self.setBackground(color: Color.clear.color, forUIControlState: .highlighted)
            self.layer.borderColor = color.color.cgColor
            self.layer.borderWidth = 2
            self.setAttributedTitle(NSMutableAttributedString(string: ""), for: .normal)
            self.setAttributedTitle(NSMutableAttributedString(string: ""), for: .highlighted)
            
        case .animation(let view, _):
            self.addSubview(view)
            view.expandToSuperviewSize()
            break
        case .noborder(let image, let color):
            self.defaultColor = color
            self.setImage(image, for: .normal)
            self.tintColor = color.color
            self.setAttributedTitle(NSMutableAttributedString(string: ""), for: .normal)
            self.setAttributedTitle(NSMutableAttributedString(string: ""), for: .highlighted)
        }

        self.layer.cornerRadius = Theme.cornerRadius
        self.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.animationView.isAnimationPlaying {
            self.animationView.size = CGSize(width: 18, height: 18)
        } else {
            self.animationView.size = .zero
        }
        self.animationView.centerOnXAndY()

        self.errorLabel.setSize(withWidth: self.width - 40)
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
        self.size = CGSize(width: width - Theme.contentOffset.doubled, height: Theme.buttonHeight)
    }

    @discardableResult
    func handleEvent(status: EventStatus) -> Future<Void, Never> {
        switch status {
        case .loading, .initial:
            return self.handleLoadingState()
        case .complete, .saved, .invalid, .custom(_), .valid, .cancelled:
            return self.handleNormalState()
        case .error(let message):
            return self.handleError(message)
        }
    }
}
