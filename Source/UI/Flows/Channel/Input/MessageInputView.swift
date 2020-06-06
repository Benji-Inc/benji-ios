//
//  MessageInputView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Lottie
import TMROLocalization

class MessageInputView: View, ActiveChannelAccessor {

    //private(set) var minHeight: CGFloat = 44
    //var oldTextViewHeight: CGFloat = 44

    //let animationView = AnimationView(name: "loading")
    //let textView = InputTextView()

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private lazy var alertConfirmation = AlertConfirmationView()
    private lazy var countView = CharacterCountView()

    private var alertAnimator: UIViewPropertyAnimator?
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private var borderColor: CGColor?

    private(set) var messageContext: MessageContext = .casual
    var editableMessage: Messageable?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .backgroundWithAlpha)

        self.addSubview(self.blurView)
//        self.addSubview(self.animationView)
//        self.animationView.contentMode = .scaleAspectFit
//        self.animationView.loopMode = .loop

        //self.addSubview(self.textView)
        self.addSubview(self.countView)
        self.countView.isHidden = true


//        self.layer.masksToBounds = true
//        self.layer.borderWidth = Theme.borderWidth
//        self.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
//        self.layer.cornerRadius = Theme.cornerRadius

    }

    override func layoutSubviews() {
        super.layoutSubviews()

        //let textViewWidth = self.width
        //self.textView.size = CGSize(width: textViewWidth, height: self.textView.currentHeight)
//        self.textView.left = 0
//        self.textView.top = 0

        self.countView.size = CGSize(width: 70, height: 20)
        self.countView.right = self.width - 5
        self.countView.bottom = self.height - 5

        //self.alertProgressView.height = self.height

        //self.overlayButton.frame = self.bounds
        self.blurView.frame = self.bounds

        self.layer.borderColor = self.borderColor ?? self.messageContext.color.color.cgColor

//        self.animationView.size = CGSize(width: 18, height: 18)
//        self.animationView.pin(.right, padding: Theme.contentOffset)
//        self.animationView.centerOnY()
    }

    func edit(message: Messageable) {
//        self.editableMessage = message
//        self.textView.text = localized(message.text)
//        self.messageContext = message.context
//        self.textView.becomeFirstResponder()
    }


}
