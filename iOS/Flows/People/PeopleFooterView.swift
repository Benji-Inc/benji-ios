//
//  PeopleFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PeopleFooterView: UICollectionReusableView {
    
    let label = ThemeLabel(font: .regular)
    let button = ThemeButton()
    
    var didSelectButton: CompletionOptional = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.label)
        self.label.setText("Choose people from your Address Book")
        self.label.textAlignment = .center
        self.label.alpha = 0.6
        
        self.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Next"))
        self.button.didSelect { [unowned self] in
            self.didSelectButton?()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.label.centerOnXAndY()
        
        self.button.setSize(with: self.width)
        self.button.match(.top, to: .bottom, of: self.label, offset: .xtraLong)
        self.button.centerOnX()
    }
}
