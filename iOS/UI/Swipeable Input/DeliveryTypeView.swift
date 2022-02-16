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
        self.layer.borderWidth = 0.5

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

        self.height = old_MessageDetailView.height
        self.width = self.label.width + Theme.ContentOffset.standard.value.doubled

        self.pin(.right)

        self.label.centerOnXAndY()
        
        self.button.expandToSuperviewWidth()
        self.button.height = 36
        self.button.centerOnXAndY()
    }

    private func createMenu(for context: MessageContext) -> UIMenu {

        let state: UIMenuElement.State = context == .respectful ? .on : .off
        let quitely = UIAction(title: "Small Talk",
                               subtitle: "No need to notify",
                               image: context.image,
                               identifier: nil,
                               discoverabilityTitle: nil,
                               attributes: [],
                               state: state) { [unowned self] _ in
            self.didSelectContext?(.respectful)
            self.configure(for: .respectful)
        }

        let urgentState: UIMenuElement.State = context == .timeSensitive ? .on : .off

        let urgent = UIAction(title: "Time Sensitive",
                              subtitle: "Notify no matter what",
                              image: context.image,
                              identifier: nil,
                              discoverabilityTitle: nil,
                              attributes: [],
                              state: urgentState) { [unowned self] _ in
            self.didSelectContext?(.timeSensitive)
            self.configure(for: .timeSensitive)
        }

        return UIMenu(title: "This message is...",
                      image: nil,
                      identifier: nil,
                      options: [.singleSelection],
                      children: [quitely, urgent])
    }
}
