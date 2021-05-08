//
//  CameraOptionsView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class CameraOptionsView: View {

    private let flipButton = CameraOptionView(type: .flip)
    private let libraryButton = CameraOptionView(type: .library)
    private let flashButton = CameraOptionView(type: .flash)

    var didSelectOption: ((CameraOptionView.OptionType, Bool) -> Void)? = nil

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.flipButton)
        self.addSubview(self.libraryButton)
        self.addSubview(self.flashButton)

        self.flipButton.didSelect { [unowned self] in
            self.flipButton.isSelected.toggle()
            self.didSelectOption?(.flip, self.flipButton.isSelected)
        }

        self.libraryButton.didSelect { [unowned self] in
            self.libraryButton.isSelected.toggle()
            self.didSelectOption?(.library, self.libraryButton.isSelected)
        }

        self.flashButton.didSelect { [unowned self] in
            self.flashButton.isSelected.toggle()
            self.didSelectOption?(.flash, self.flashButton.isSelected)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.flipButton.width = self.width
        self.flipButton.height = self.height * 0.33
        self.flipButton.pin(.top)

        self.flashButton.width = self.width
        self.flashButton.height = self.height * 0.33
        self.flashButton.match(.top, to: .bottom, of: self.flipButton)

        self.libraryButton.width = self.width
        self.libraryButton.height = self.height * 0.33
        self.libraryButton.match(.top, to: .bottom, of: self.flashButton)
    }
}

class CameraOptionView: View {

    private var cancellables = Set<AnyCancellable>()

    enum OptionType {
        case flip
        case library
        case flash

        var image: UIImage? {
            switch self {
            case .flip:
                return UIImage(systemName: "arrow.triangle.2.circlepath.camera")
            case .library:
                return UIImage(systemName: "photo.on.rectangle")
            case .flash:
                return UIImage(systemName: "bolt.fill")
            }
        }

        var selectedImage: UIImage? {
            switch self {
            case .flip:
                return UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill")
            case .library:
                return UIImage(systemName: "photo.on.rectangle.fill")
            case .flash:
                return UIImage(systemName: "bolt.slash.fill")
            }
        }

        var title: Localized {
            switch self {
            case .flip:
                return "flip"
            case .library:
                return "library"
            case .flash:
                return "flash"
            }
        }
    }

    let type: OptionType

    private let imageView = UIImageView()
    private let label = Label(font: .small)

    @Published var isSelected: Bool = false

    init(type: OptionType) {
        self.type = type
        super.init()
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.tintColor = Color.background4.color
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = self.type.image

        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.setText(self.type.title)

        self.$isSelected.mainSink { isSelected in

            if isSelected {
                self.imageView.image = self.type.image
                self.label.setText(self.type.title)
            } else {
                self.imageView.image = self.type.selectedImage
                self.label.setText(self.type.title)
            }

            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = self.width * 0.6
        self.imageView.pin(.top)
        self.imageView.centerOnX()

        self.imageView.layer.shadowColor = Color.background1.color.cgColor
        self.imageView.layer.shadowOpacity = 0.8
        self.imageView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.imageView.layer.shadowRadius = 10
        self.imageView.layer.masksToBounds = false

        self.label.setSize(withWidth: self.width)
        self.label.match(.top, to: .bottom, of: self.imageView, offset: 2)
        self.label.centerOnX()
    }
}
