//
//  WalletSegmentControl.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletSegmentControl: UISegmentedControl {
    
    enum SegmentType: Int {
        case achievements
        case you
        case connections
    }
    
    var didSelectSegmentIndex: ((SegmentType) -> Void)? = nil
    
    init() {
        
        super.init(frame: .zero)
        
        let rewardsAction = UIAction(title: "Rewards") { _ in
            self.didSelectSegmentIndex?(.achievements)
        }
        
        let youAction = UIAction(title: "You") { _ in
            self.didSelectSegmentIndex?(.you)
        }
        
        let connectionsAction = UIAction(title: "Connections") { _ in
            self.didSelectSegmentIndex?(.connections)
        }
            
        self.insertSegment(action: rewardsAction, at: 0, animated: false)
        self.insertSegment(action: youAction, at: 1, animated: false)
        self.insertSegment(action: connectionsAction, at: 2, animated: false)

        let attributes: [NSAttributedString.Key : Any] = [.font : FontType.small.font, .foregroundColor : ThemeColor.white.color.withAlphaComponent(0.6)]
        self.setTitleTextAttributes(attributes, for: .normal)
        self.setTitleTextAttributes(attributes, for: .selected)
        self.setTitleTextAttributes(attributes, for: .highlighted)
        self.selectedSegmentTintColor = ThemeColor.white.color.withAlphaComponent(0.1)
        self.selectedSegmentIndex = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
