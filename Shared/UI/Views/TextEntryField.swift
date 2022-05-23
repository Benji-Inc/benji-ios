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

    private let speechBubble = SpeechBubbleView(orientation: .down)
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
        
        self.addSubview(self.speechBubble)
        self.speechBubble.tailLength = 0 
        self.speechBubble.setBubbleColor(ThemeColor.B1.color,
                                         animated: false)

        self.showShadow(withOffset: 8)
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.textField)

        self.textField.returnKeyType = .done
        self.textField.adjustsFontSizeToFitWidth = true
        self.textField.keyboardAppearance = .dark
        self.textField.textAlignment = .center

        if let placeholder = self.placeholder {
            let attributed = AttributedString(placeholder,
                                              fontType: .regular,
                                              color: .whiteWithAlpha)
            self.textField.setPlaceholder(attributed: attributed)
            self.textField.setDefaultAttributes(style: StringStyle(font: .regular, color: .white),
                                                alignment: .center)
        }

        if let tf = self.textField as? TextField {
            tf.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }

        self.clipsToBounds = false
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        return 64
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.speechBubble.expandToSuperviewSize()
        
        let maxWidth = self.width - Theme.ContentOffset.long.value.doubled
        self.textField.size = CGSize(width: maxWidth, height: 40)
        self.textField.pin(.left, offset: .long)
        self.textField.pin(.top, offset: .long)
    }
}
