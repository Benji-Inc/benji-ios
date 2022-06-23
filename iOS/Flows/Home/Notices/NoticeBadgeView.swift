//
//  NoticeBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class NoticeBadgeView: BadgeCounterView {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        NoticeStore.shared.$notices.mainSink { [unowned self] notices in
            self.counter.setValue(Float(notices.count))
            self.animateChanges(shouldShow: notices.count > 0)
        }.store(in: &self.cancellables)
    }
}
