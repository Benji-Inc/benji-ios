//
//  BaseMessageCell.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Lottie

class BaseMessageCell: UICollectionViewCell {

    let avatarView = AvatarView()
    var didTapMessage: () -> Void = {}

    private(set) var currentMessage: Messageable?
    private(set) var attributes: ChannelCollectionViewLayoutAttributes?
    private var animationView = AnimationView(name: "error")

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initializeViews()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attributes = layoutAttributes as? ChannelCollectionViewLayoutAttributes else { return }
        self.attributes = attributes
        self.layoutContent(with: attributes)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentMessage = nil
        self.attributes = nil
        self.animationView.alpha = 0
    }

    // OVERRIDES

    func initializeViews() {

        self.contentView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.contentView.addSubview(self.avatarView)
    }

    func configure(with message: Messageable) {
        self.currentMessage = message
        if !message.isFromCurrentUser {
            self.avatarView.set(avatar: message.avatar)
        }

        self.handleIsConsumed(for: message)
        self.handleStatus(for: message)
    }

    func showError() {
        self.animationView.forceDisplayUpdate()

        UIView.animate(withDuration: 0.2) {
            self.animationView.alpha = 1
        }

        self.animationView.play()
    }

    func handleIsConsumed(for message: Messageable) {}

    func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        self.avatarView.frame = attributes.attributes.avatarFrame
        self.animationView.size = CGSize(width: 22, height: 22)
    }

    // PRIVATE

    private func handleStatus(for message: Messageable) {
        self.animationView.alpha = 0

        if message.isFromCurrentUser {
            switch message.status {
            case .error:
                self.showError()
            default:
                break
            }
        }
    }
}

class MessageBubbleView: View {
    var indexPath: IndexPath?

    // Shimmer Animation Extensions

    enum ShimmerDirection: Int {
        case topToBottom = 0
        case bottomToTop
        case leftToRight
        case rightToLeft
    }

    func startShimmer(animationSpeed: Float = 1.4,
                      direction: ShimmerDirection = .leftToRight,
                      repeatCount: Float = MAXFLOAT,
                      groupDuration: Double = 0,
                      isDiagonal: Bool = false) {

        let lightColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7).cgColor
        let blackColor = UIColor.black.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [blackColor, lightColor, blackColor]
        gradientLayer.frame = CGRect(x: -self.bounds.size.width, y: -self.bounds.size.height, width: 3 * self.bounds.size.width, height: 3 * self.bounds.size.height)

        // Rotates the gradient around the center point for axis of interest (horizontal or vertical) for the direction
        let highVal : CGFloat = isDiagonal ? 0.75 : 0.5
        let lowVal : CGFloat = isDiagonal ? 0.25 : 0.5

        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: lowVal, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: highVal, y: 1.0)

        case .bottomToTop:
            gradientLayer.startPoint = CGPoint(x: highVal, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: lowVal, y: 0.0)

        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0.0, y: lowVal)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: highVal)

        case .rightToLeft:
            gradientLayer.startPoint = CGPoint(x: 1.0, y: highVal)
            gradientLayer.endPoint = CGPoint(x: 0.0, y: lowVal)
        }

        gradientLayer.locations =  [0.35, 0.50, 0.65]
        self.layer.mask = gradientLayer

        CATransaction.begin()
        let shimmer = CABasicAnimation(keyPath: "locations")
        shimmer.fromValue = [0.0, 0.1, 0.2]
        shimmer.toValue = [0.8, 0.9, 1.0]
        shimmer.duration = CFTimeInterval(animationSpeed)
        shimmer.fillMode = .forwards

        CATransaction.setCompletionBlock { [weak self] in
            guard let `self` = self else { return }
            self.layer.removeAllAnimations()
            self.layer.mask = nil
        }

        let group = CAAnimationGroup()
        group.animations = [shimmer]
        group.duration = groupDuration
        group.repeatCount = repeatCount

        gradientLayer.add(group, forKey: "shimmerAnimation")
        CATransaction.commit()
    }

    func stopShimmeringAnimation() {
        self.layer.removeAllAnimations()
        self.layer.mask = nil
    }
}
