//
//  ConversationsSegmentControl.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationsSegmentControl: UISegmentedControl {
    
    enum SegmentType: Int {
        case recents
        case all
        case unread
    }
    
    var didSelectSegmentIndex: ((SegmentType) -> Void)? = nil
    
    init() {
        
        super.init(frame: .zero)
        
        let recentsAction = UIAction(title: "Recents") { _ in
            self.didSelectSegmentIndex?(.recents)
        }
        
        let allAction = UIAction(title: "All") { _ in
            self.didSelectSegmentIndex?(.all)
        }
        
        let archiveAction = UIAction(title: "Urgent") { _ in
            self.didSelectSegmentIndex?(.unread)
        }
            
        self.insertSegment(action: recentsAction, at: 1, animated: false)
        self.insertSegment(action: allAction, at: 2, animated: false)
        self.insertSegment(action: archiveAction, at: 0, animated: false)

        let attributes: [NSAttributedString.Key : Any] = [.font : FontType.small.font, .foregroundColor : ThemeColor.white.color.withAlphaComponent(0.6)]
        self.setTitleTextAttributes(attributes, for: .normal)
        self.setTitleTextAttributes(attributes, for: .selected)
        self.setTitleTextAttributes(attributes, for: .highlighted)
        self.selectedSegmentTintColor = ThemeColor.white.color.withAlphaComponent(0.1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
