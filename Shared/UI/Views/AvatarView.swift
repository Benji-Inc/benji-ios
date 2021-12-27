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

    var initials: String? {
        didSet {
            self.setImageFrom(initials: self.initials)
        }
    }

    private let label = ThemeLabel(font: .regularBold, textColor: .textColor)

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
        guard let initials = initials else {
            self.label.text = nil
            return
        }

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
        self.insertSubview(self.label, aboveSubview: self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.masksToBounds = true
        self.imageView.clipsToBounds = true
        self.setCorner(radius: Theme.innerCornerRadius)
        self.imageView.set(backgroundColor: .white)
    }

    // MARK: - Open setters

    func set(avatar: Avatar) {
        Task {
            if let user = avatar as? User {
                self.subscribeToUpdates(for: user)
            } else if let userId = avatar.userObjectId,
                      let user = await UserStore.shared.findUser(with: userId) {
                self.subscribeToUpdates(for: user)
            }
        }.add(to: self.taskPool)
        
        self.avatar = avatar
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
        
        self.displayable = avatar
    }
    
    override func showResult(for image: UIImage?) {
        super.showResult(for: image)
        
        if image.isNil, let avatar = self.avatar {
            self.initials = avatar.initials
            self.blurView.effect = nil
        }
    }
    
    private func subscribeToUpdates(for user: User) {
        UserStore.shared.$userUpdated.filter { updatedUser in
            updatedUser?.objectId == user.userObjectId
        }.mainSink { updatedUser in
            self.displayable = updatedUser
        }.store(in: &self.cancellables)
    }

    func setCorner(radius: CGFloat?) {
        guard let radius = radius else {
            //if corner radius not set default to Circle
            let cornerRadius = min(frame.width, frame.height)
            self.imageView.layer.cornerRadius = cornerRadius/2
            return
        }
        self.radius = radius
        self.imageView.layer.cornerRadius = radius
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.expandToSuperviewSize()
    }

    override func reset() {
        super.reset()

        self.initials = nil
        self.blurView.showBlur(false)
    }
}

fileprivate extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
