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
        self.addSubview(self.button)

        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.D6withAlpha.color.cgColor
        self.layer.borderWidth = 0.25

        self.clipsToBounds = false

        self.button.showsMenuAsPrimaryAction = true
    }

    func configure(for context: MessageContext) {
        self.label.setText(context.displayName)
        self.button.menu = self.createMenu(for: context)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: 200)

        self.height = 20
        self.width = self.label.width + Theme.ContentOffset.short.value.doubled

        self.pin(.right)

        self.label.centerOnXAndY()
        
        self.button.expandToSuperviewWidth()
        self.button.height = 36
        self.button.centerOnXAndY()
    }

    private func createMenu(for context: MessageContext) -> UIMenu {

        let state: UIMenuElement.State = context == .passive ? .on : .off
        let quitely = UIAction(title: "Quietly",
                               image: UIImage(systemName: "bell.slash"),
                               identifier: nil,
                               discoverabilityTitle: nil,
                               attributes: [],
                               state: state) { [unowned self] _ in
            self.didSelectContext?(.passive)
            self.configure(for: .passive)
        }

        let urgentState: UIMenuElement.State = context == .timeSensitive ? .on : .off

        let urgent = UIAction(title: "Urgently",
                               image: UIImage(systemName: "bell.badge"),
                               identifier: nil,
                               discoverabilityTitle: nil,
                               attributes: [],
                               state: urgentState) { [unowned self] _ in
            self.didSelectContext?(.timeSensitive)
            self.configure(for: .timeSensitive)
        }

        return UIMenu(title: "Select delivery method",
                      image: nil,
                      identifier: nil,
                      options: [.singleSelection],
                      children: [quitely, urgent])
    }
}
