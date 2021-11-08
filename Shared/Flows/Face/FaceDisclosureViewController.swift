//
//  FaceDisclosureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class FaceDisclosureViewController: DisclosureModalViewController {

    enum CaptureType {
        case smiling
        case eyesClosed

        var title: Localized {
            switch self {
            case .smiling:
                return "Let’s Review"
            case .eyesClosed:
                return "Let’s Review"
            }
        }

        var description: HightlightedPhrase {
            switch self {
            case .smiling:
                return HightlightedPhrase(text: "Your smile tells everyone you are available and will recieve thier notifications.", highlightedWords: ["available", "new"])
            case .eyesClosed:
                return HightlightedPhrase(text: "When people see your eyes closed it tells them you are focused and all notifications are delivered silently.", highlightedWords: ["focused", "silently"])
            }
        }

        var displayable: ImageDisplayable? {
            switch self {
            case .smiling:
                return User.current()?.smallImage
            case .eyesClosed:
                return User.current()?.focusImage
            }
        }
    }

    private let imageView = AvatarView()
    let button = Button()

    private let captureType: CaptureType

    init(with type: CaptureType) {
        self.captureType = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.imageView)
        self.imageView.displayable = self.captureType.displayable
        self.imageView.tintColor = .white

        self.titleLabel.setText(self.captureType.title)
        self.updateDescription(with: self.captureType.description)

        self.contentView.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: "Got it"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.setSize(for: self.view.width * 0.25)
        self.imageView.match(.top, to: .bottom, of: self.titleLabel, offset: Theme.contentOffset)
        self.imageView.centerOnX()

        self.descriptionLabel.match(.top, to: .bottom, of: self.imageView, offset: Theme.contentOffset)

        self.button.expandToSuperviewWidth()
        self.button.height = Theme.buttonHeight
        self.button.pin(.bottom, padding: Theme.contentOffset)
    }
}
