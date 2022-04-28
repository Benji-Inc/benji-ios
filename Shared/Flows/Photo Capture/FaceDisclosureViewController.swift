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

/// A view controller that gives feedback on selfies taken by the user.
class FaceDisclosureViewController: DisclosureModalViewController {

    enum CaptureType {
        case smiling

        var title: Localized {
            switch self {
            case .smiling:
                return "Success"
            }
        }

        var description: HightlightedPhrase {
            switch self {
            case .smiling:
                return HightlightedPhrase(text: "😁 Looking good!", highlightedWords: [])
            }
        }

        var displayable: ImageDisplayable? {
            switch self {
            case .smiling:
                return User.current()?.smallImage
            }
        }
    }

    private let personView = PersonView()
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

        self.view.addSubview(self.personView)
        self.personView.state = .loading
        self.personView.tintColor = .white
        self.personView.layer.borderColor = ThemeColor.white.color.cgColor
        self.personView.layer.borderWidth = 2
        self.personView.layer.cornerRadius = Theme.cornerRadius

        self.titleLabel.setText("Uploading")

        self.button.isHidden = true
        self.contentView.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Next"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.personView.setSize(forHeight: self.view.width * 0.25)
        self.personView.match(.top, to: .bottom, of: self.titleLabel, offset: .xtraLong)
        self.personView.centerOnX()

        self.descriptionLabel.match(.top, to: .bottom, of: self.personView, offset: .xtraLong)

        self.button.expandToSuperviewWidth()
        self.button.height = Theme.buttonHeight
        self.button.pinToSafeAreaBottom()
    }

    func updateUser(with data: Data) async throws {
        guard let currentUser = User.current() else { return }

        switch self.captureType {
        case .smiling:
            let file = PFFileObject(name:"small_image.heic", data: data)
            currentUser.smallImage = file
        }

        do {
            try await currentUser.saveToServer()
            Task.onMainActor {
                self.updateUI(data: data)
            }
        } catch {
            self.personView.state = .error
            self.titleLabel.setText("Error")
            throw error
        }
    }

    private func updateUI(data: Data) {
        self.titleLabel.setText(self.captureType.title)
        self.updateDescription(with: self.captureType.description)
        self.personView.displayable = UIImage(data: data)
        self.button.isHidden = false
        self.view.layoutNow()
    }
}
