//
//  DeliveryTypeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class DeliveryTypeView: BaseView {

    let label = ThemeLabel(font: .small)
    let button = ThemeButton()

    var didSelectContext: ((MessageContext) -> Void)?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.label.textAlignment = .right
        self.addSubview(self.button)

        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.layer.borderWidth = 0.5

        self.clipsToBounds = false

        self.button.showsMenuAsPrimaryAction = true
    }
    
    func reset() {
        self.label.setText("This is...")
        self.button.menu = self.createMenu(for: .respectful)
        self.setNeedsLayout()
    }

    func configure(for context: MessageContext) {
        self.label.setText(context.displayName)
        self.button.menu = self.createMenu(for: context)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: 200)

        self.height = old_MessageDetailView.height
        self.width = self.label.width + Theme.ContentOffset.standard.value.doubled

        self.pin(.right)

        self.label.centerOnY()
        self.label.pin(.left, offset: .standard)
        
        self.button.expandToSuperviewWidth()
        self.button.height = 36
        self.button.centerOnXAndY()
    }

    private func createMenu(for context: MessageContext) -> UIMenu {
        
        var actions: [UIAction] = []
        MessageContext.allCases.forEach { value in
            let state: UIMenuElement.State = context == value ? .on : .off
            let action = UIAction(title: value.displayName,
                                   subtitle: value.description,
                                   image: value.image,
                                   identifier: nil,
                                   discoverabilityTitle: nil,
                                   attributes: [],
                                   state: state) { [unowned self] _ in
                self.didSelectContext?(value)
                self.configure(for: value)
            }
            actions.append(action)
        }

        return UIMenu(title: "This is...",
                      image: nil,
                      identifier: nil,
                      options: [.singleSelection],
                      children: actions)
    }
}
