//
//  TextEntryField.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class TextEntryField: View, Sizeable {

    private(set) var textField: UITextField
    private let titleLabel = Label(font: .smallBold)
    private let title: Localized
    private let placeholder: Localized?
    let button = Button()

    init(with textField: UITextField,
         title: Localized,
         placeholder: Localized?) {

        self.textField = textField
        self.title = title
        self.placeholder = placeholder

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.titleLabel)
        self.titleLabel.setText(self.title)
        self.addSubview(self.textField)
        self.addSubview(self.button)

        self.textField.returnKeyType = .done
        self.textField.adjustsFontSizeToFitWidth = true
        self.textField.keyboardAppearance = .dark

        if let placeholder = self.placeholder {
            let attributed = AttributedString(placeholder, fontType: .medium, color: .background3)
            self.textField.setPlaceholder(attributed: attributed)
            self.textField.setDefaultAttributes(style: StringStyle(font: .medium, color: .white))
        }

        if let tf = self.textField as? TextField {
            tf.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }

        self.clipsToBounds = true
    }

    func getHeight(for width: CGFloat) -> CGFloat {

        self.titleLabel.setSize(withWidth: width)
        self.titleLabel.pin(.top)
        self.titleLabel.pin(.left)

        self.textField.size = CGSize(width: width, height: 40)
        self.textField.pin(.left)
        self.textField.match(.top, to: .bottom, of: self.titleLabel, offset: 10)

        self.button.height = Theme.buttonHeight
        self.button.width = width 
        self.button.match(.top, to: .bottom, of: self.textField, offset: 10)
        self.button.pin(.left)

        return self.button.bottom
    }
}
