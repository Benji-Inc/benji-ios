//
//  NoticeContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeContentView: BaseView {
    
    var didSelectRemove: CompletionOptional = nil
    var didSelectPrimaryOption: CompletionOptional = nil
    var didSelectSecondaryOption: CompletionOptional = nil
    
    private let removeButton = ThemeSymbolButton()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B6)
        self.layer.cornerRadius = Theme.cornerRadius
        
        self.removeButton.set(symbol: .xMarkCircleFill, pointSize: 26)
        self.removeButton.didSelect { [unowned self] in
            self.didSelectRemove?()
        }
        
        self.addSubview(self.removeButton)
    }
    
    func configure(for notice: SystemNotice) async {}
    
    func showError() {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.bringSubviewToFront(self.removeButton)
        
        self.removeButton.squaredSize = 44
        self.removeButton.pin(.top)
        self.removeButton.pin(.right)
    }
}
