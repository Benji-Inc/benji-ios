//
//  AvatarView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/23/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class AvatarView: DisplayableImageView {

    // MARK: - Properties

    var borderColor: Color = .clear {
        didSet {
            self.setBorder(color: self.borderColor)
        }
    }

    var initials: String? {
        didSet {
            self.setImageFrom(initials: self.initials)
        }
    }

    private let label = Label(font: .regularBold, textColor: .textColor)

    private var radius: CGFloat?

    // MARK: - Overridden Properties
    
    override var frame: CGRect {
        didSet {
            self.setCorner(radius: self.radius)
        }
    }

    override var bounds: CGRect {
        didSet {
            self.setCorner(radius: self.radius)
        }
    }

    // MARK: - Initializers

    override init() {
        super.init()
        self.prepareView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.prepareView()
    }

    private func setImageFrom(initials: String?) {
        guard let initials = initials else { return }

        self.imageView.isHidden = true
        self.label.isHidden = false
        self.label.setText(initials.uppercased())
        self.label.textAlignment = .center
        self.state = .success
        self.layoutNow()
    }

    func getSize(for height: CGFloat) -> CGSize {
        return CGSize(width: height, height: height)
    }

    func setSize(for height: CGFloat) {
        self.size = self.getSize(for: height)
    }

    private func prepareView() {
        self.insertSubview(self.label, belowSubview: self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.layer.masksToBounds = true
        self.clipsToBounds = true
        self.setCorner(radius: 5)
        self.layer.borderColor = self.borderColor.color.cgColor
        self.layer.borderWidth = 2
        self.set(backgroundColor: .white)
    }

    // MARK: - Open setters

    func set(avatar: Avatar) {
        if avatar is User {
            UserStore.shared.$userUpdated.filter { user in
                user?.objectId == avatar.userObjectID
            }.mainSink { user in
                self.displayable = user
            }.store(in: &self.cancellables)
        }

        self.displayable = avatar

        self.avatar = avatar
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)

        guard avatar.image == nil, avatar.userObjectID == nil else { return }
        self.initials = avatar.initials
        self.blurView.effect = nil 
        self.layoutNow()
    }

    func setCorner(radius: CGFloat?) {
        guard let radius = radius else {
            //if corner radius not set default to Circle
            let cornerRadius = min(frame.width, frame.height)
            self.layer.cornerRadius = cornerRadius/2
            return
        }
        self.radius = radius
        self.layer.cornerRadius = radius
    }

    func setBorder(color: Color) {
        self.layer.borderColor = color.color.cgColor
        self.layer.borderWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
    }

    override func reset() {
        super.reset()

        self.label.isHidden = true
        self.imageView.isHidden = false
        self.label.text = nil
    }
}

fileprivate extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
