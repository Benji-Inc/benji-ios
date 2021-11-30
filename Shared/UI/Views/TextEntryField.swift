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
    private let placeholder: Localized?

    init(with textField: UITextField, placeholder: Localized?) {

        self.textField = textField
        self.placeholder = placeholder

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .white)

        self.addSubview(self.textField)

        self.textField.returnKeyType = .done
        self.textField.adjustsFontSizeToFitWidth = true
        self.textField.keyboardAppearance = .dark
        self.textField.textAlignment = .center

        if let placeholder = self.placeholder {
            let attributed = AttributedString(placeholder,
                                              fontType: .medium,
                                              color: .lightGray)
            self.textField.setPlaceholder(attributed: attributed)
            self.textField.setDefaultAttributes(style: StringStyle(font: .medium, color: .darkGray),
                                                alignment: .center)
        }

        if let tf = self.textField as? TextField {
            tf.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }

        self.clipsToBounds = true
    }

    func getHeight(for width: CGFloat) -> CGFloat {

        self.textField.size = CGSize(width: Theme.getPaddedWidth(with: width), height: 40)
        self.textField.pinToSafeAreaLeft()
        self.textField.pin(.top, offset: .standard)

        return self.textField.bottom + Theme.ContentOffset.standard.value
    }
}
