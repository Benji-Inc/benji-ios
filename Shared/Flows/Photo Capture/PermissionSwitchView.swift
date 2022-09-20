//
//  PermissionSwitchView.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization
import UIKit

class PermissionSwitchView: BaseView {

    enum State {
        case enabled
        case disabled
        case hidden
    }

    enum PermissionType {
        case focus
        case notificaitons
        case location
        case weather

        var text: Localized {
            switch self {
            case .focus:
                return "Focus Status"
            case .notificaitons:
                return "Notifications"
            case .location:
                return "Current Location"
            case .weather:
                return "Weather"
            }
        }
    }

    var isON: Bool {
        return self.switchView.isOn
    }

    let type: PermissionType
    private let label = ThemeLabel(font: .smallBold)
    private(set) var  switchView = UISwitch()
    @Published var state: State = .hidden

    init(with type: PermissionType) {
        self.type = type
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.alpha = 0 

        self.addSubview(self.label)
        self.label.setText(self.type.text)
        self.addSubview(self.switchView)

        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
            self.updateUI(for: state)
        }.store(in: &self.cancellables)

        self.layer.borderColor = ThemeColor.white.color.cgColor
        self.layer.borderWidth = 2
        
        self.switchView.onTintColor = ThemeColor.whiteWithAlpha.color
        self.switchView.thumbTintColor = ThemeColor.white.color
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.roundCorners()

        self.label.setSize(withWidth: self.width)
        self.label.pin(.left, offset: .xtraLong)
        self.label.centerOnY()

        self.switchView.centerOnY()
        self.switchView.pin(.right, offset: .long)
    }

    private func updateUI(for state: State) {

        switch state {
        case .enabled:
            self.isUserInteractionEnabled = true
        case .disabled, .hidden:
            self.isUserInteractionEnabled = false
        }

        UIView.animate(withDuration: Theme.animationDurationStandard) {
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
    
    func setSize(with width: CGFloat) {
        self.size = CGSize(width: Theme.getPaddedWidth(with: width), height: Theme.buttonHeight)
    }
}
