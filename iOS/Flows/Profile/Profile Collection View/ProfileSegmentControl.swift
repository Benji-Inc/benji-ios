//
//  ProfileSegmentControl.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileSegmentControl: UISegmentedControl {
    
    enum SegmentType: Int {
        case moments
        case conversations
    }
    
    var didSelectSegmentIndex: ((SegmentType) -> Void)? = nil
    
    init() {
        
        super.init(frame: .zero)
        
        let conversationsAction = UIAction(title: "Conversations") { _ in
            self.didSelectSegmentIndex?(.conversations)
        }
        
        let momentsAction = UIAction(title: "Moments") { _ in
            self.didSelectSegmentIndex?(.moments)
        }
            
        self.insertSegment(action: momentsAction, at: 0, animated: false)
        self.insertSegment(action: conversationsAction, at: 1, animated: false)

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
