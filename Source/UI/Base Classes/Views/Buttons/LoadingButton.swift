//
//  AlertButton.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LoadingButton: Button {

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let alphaOutAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                          curve: .linear,
                                                          animations: nil)

    private let alphaInAnimator = UIViewPropertyAnimator(duration: Theme.animationDuration,
                                                         curve: .linear,
                                                         animations: nil)

    private let shouldRound: Bool = true
    var canShowLoading: Bool = true

    var isLoading: Bool = false {
        didSet {
            runMain {
                guard self.canShowLoading else { return }

                if self.isLoading {
                    self.showLoading()
                } else {
                    self.hideLoading()
                }

                self.isUserInteractionEnabled = !self.isLoading
                self.isEnabled = !self.isLoading
            }
        }
    }

    init() {
        super.init(frame: .zero)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {

        // Disable when the keyboard is shown
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)

        self.addSubview(self.loadingIndicator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.loadingIndicator.centerOnXAndY()
    }

    @objc func keyboardWillShow(notification: Notification) {
        self.isEnabled = false
    }

    @objc func keyboardWillHide(notification: Notification) {
        self.isEnabled = true
    }

    func set(style: ButtonStyle,
             didSelect: @escaping () -> Void) {

        self.didSelect = didSelect
        self.set(style: style)
    }

    private func showLoading() {
        self.alphaOutAnimator.stopAnimation(true)
        self.alphaOutAnimator.addAnimations {
            for view in self.subviews {
                if let label = view as? UILabel {
                    label.alpha = 0.1
                }
            }
        }
        self.alphaOutAnimator.startAnimation(afterDelay: 0.1)
        self.alphaOutAnimator.addCompletion { (position) in
            if position == .end {
                self.loadingIndicator.isHidden = !self.isLoading
                self.loadingIndicator.startAnimating()
            }
        }
    }

    private func hideLoading() {
        self.alphaInAnimator.stopAnimation(true)
        self.alphaInAnimator.addAnimations {
            for view in self.subviews {
                if let label = view as? UILabel {
                    label.alpha = 1.0
                }
            }
        }
        self.alphaInAnimator.startAnimation()
        self.loadingIndicator.isHidden = !self.isLoading
        self.loadingIndicator.stopAnimating()
    }
}
