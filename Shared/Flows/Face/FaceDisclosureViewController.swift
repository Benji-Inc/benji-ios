//
//  FaceDisclosureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Localization

class FaceDisclosureViewController: DisclosureModalViewController {

    enum CaptureType {
        case smiling

        var title: Localized {
            switch self {
            case .smiling:
                return "Let’s Review"
            }
        }

        var description: HightlightedPhrase {
            switch self {
            case .smiling:
                return HightlightedPhrase(text: "Your smile tells everyone you are available and will recieve thier notifications.", highlightedWords: ["available"])
            }
        }

        var displayable: ImageDisplayable? {
            switch self {
            case .smiling:
                return User.current()?.smallImage
            }
        }
    }

    private let imageView = AvatarView()
    let button = ThemeButton()

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
        self.imageView.state = .loading
        self.imageView.tintColor = .white

        self.titleLabel.setText("Uploading")

        self.button.isHidden = true
        self.contentView.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: "Got it"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.imageView.setSize(for: self.view.width * 0.25)
        self.imageView.match(.top, to: .bottom, of: self.titleLabel, offset: .xtraLong)
        self.imageView.centerOnX()

        self.descriptionLabel.match(.top, to: .bottom, of: self.imageView, offset: .xtraLong)

        self.button.expandToSuperviewWidth()
        self.button.height = Theme.buttonHeight
        self.button.pinToSafeAreaBottom()
    }

    func updateUser(with data: Data) async throws {
        guard let currentUser = User.current() else { return }

        switch self.captureType {
        case .smiling:
            let file = PFFileObject(name:"small_image.jpeg", data: data)
            currentUser.smallImage = file
        }

        do {
            try await currentUser.saveToServer()
            Task.onMainActor {
                self.updateUI(data: data)
            }
        } catch {
            self.imageView.state = .error
            self.titleLabel.setText("Error")
            throw error
        }
    }

    private func updateUI(data: Data) {
        self.titleLabel.setText(self.captureType.title)
        self.updateDescription(with: self.captureType.description)
        self.imageView.displayable = UIImage(data: data)
        self.button.isHidden = false
        self.view.layoutNow()
    }
}
