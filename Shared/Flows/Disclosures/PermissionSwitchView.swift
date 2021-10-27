//
//  PermissionSwitchView.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class PermissionSwitchView: View {

    private var cancellables = Set<AnyCancellable>()

    enum State {
        case enabled
        case disabled
        case hidden
    }

    enum PermissionType {
        case focus
        case notificaitons

        var image: UIImage {
            switch self {
            case .focus:
                return UIImage(systemName: "moon.circle")!
            case .notificaitons:
                return UIImage(systemName: "bell.badge")!
            }
        }

        var text: Localized {
            switch self {
            case .focus:
                return "Focus Status"
            case .notificaitons:
                return "Notificaitons"
            }
        }
    }

    var isON: Bool {
        return self.switchView.isOn
    }

    let type: PermissionType
    private let imageView = DisplayableImageView()
    private let label = Label(font: .smallBold)
    private(set) var  switchView = UISwitch()
    @Published var state: State = .hidden

    init(with type: PermissionType) {
        self.type = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.alpha = 0 

        self.addSubview(self.imageView)
        self.imageView.displayable = self.type.image
        self.imageView.tintColor = Color.white.color

        self.addSubview(self.label)
        self.label.setText(self.type.text)
        self.addSubview(self.switchView)

        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
            self.updateUI(for: state)
        }.store(in: &self.cancellables)

        self.layer.borderColor = Color.white.color.cgColor
        self.layer.borderWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.roundCorners()

        self.imageView.squaredSize = self.height - Theme.contentOffset
        self.imageView.pin(.left, padding: Theme.contentOffset.half)
        self.imageView.centerOnY()

        self.label.setSize(withWidth: self.width)
        self.label.match(.left, to: .right, of: self.imageView, offset: Theme.contentOffset.half)
        self.label.centerOnY()

        self.switchView.centerOnY()
        self.switchView.pin(.right, padding: Theme.contentOffset.half)
    }

    private func updateUI(for state: State) {

        switch state {
        case .enabled:
            self.isUserInteractionEnabled = true
        case .disabled, .hidden:
            self.isUserInteractionEnabled = false
        }

        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .enabled:
                self.alpha = 1.0
            case .disabled:
                self.alpha = 0.25
            case .hidden:
                self.alpha = 0.0
            }
        }
    }
}
