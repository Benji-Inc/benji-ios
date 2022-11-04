//
//  TextEntryField.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization
import UIKit
 
class TextEntryField: BaseView, Sizeable {

    private let lineView = BaseView()
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
    
        self.showShadow(withOffset: 8)
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.textField)
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .whiteWithAlpha)
        
        self.textField.font = FontType.medium.font
        self.textField.returnKeyType = .done
        self.textField.adjustsFontSizeToFitWidth = true
        self.textField.keyboardAppearance = .dark
        self.textField.textAlignment = .left

        if let placeholder = self.placeholder {
            let attributed = AttributedString(placeholder,
                                              fontType: .medium,
                                              color: .whiteWithAlpha)
            self.textField.setPlaceholder(attributed: attributed)
            self.textField.setDefaultAttributes(style: StringStyle(font: .medium, color: .white),
                                                alignment: .left)
        }

        if let tf = self.textField as? TextField {
            tf.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }

        self.clipsToBounds = false
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        return 56
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        let maxWidth = self.width - Theme.ContentOffset.long.value.doubled
        self.textField.size = CGSize(width: maxWidth, height: 40)
        self.textField.pin(.left, offset: .long)
        self.textField.pin(.top, offset: .long)
        
        let padding: CGFloat = 14

        self.lineView.width = self.width - padding.doubled
        self.lineView.height = 2
        self.lineView.pin(.bottom)
        self.lineView.centerOnX()
    }
}
