//
//  NoticeContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticeContentView: BaseView {
    
    var didSelectPrimaryOption: CompletionOptional = nil
    var didSelectSecondaryOption: CompletionOptional = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B6)
        self.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(for notice: SystemNotice) {}
}
