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
                return HightlightedPhrase(text: "When people see your smiling face in Jibber it tells them you are available to chat and you’ll get a new message notification.", highlightedWords: ["available"])
            case .eyesClosed:
                return HightlightedPhrase(text: "When people see your eyes closed in Jibber it tells them you are busy and all new messages are delivered silently.", highlightedWords: ["busy", "silently"])
            }
        }

        var image: UIImage {
            switch self {
            case .smiling:
                return UIImage(systemName: "face.smiling.fill")!
            case .eyesClosed:
                return UIImage(systemName: "eyebrow")!
            }
        }
    }

    private let imageView = DisplayableImageView()
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
        self.imageView.displayable = self.captureType.image
        self.imageView.tintColor = .white

        self.titleLabel.setText(self.captureType.title)
        self.updateDescription(with: self.captureType.description)

        self.contentView.addSubview(self.button)
        self.button.set(style: .normal(color: .lightGray, text: "Got it"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.squaredSize = self.view.width * 0.25
        self.imageView.match(.top, to: .bottom, of: self.titleLabel, offset: Theme.contentOffset)
        self.imageView.centerOnX()

        self.descriptionLabel.match(.top, to: .bottom, of: self.imageView, offset: Theme.contentOffset)

        self.button.expandToSuperviewWidth()
        self.button.height = Theme.buttonHeight
        self.button.pin(.bottom, padding: Theme.contentOffset)
    }
}
