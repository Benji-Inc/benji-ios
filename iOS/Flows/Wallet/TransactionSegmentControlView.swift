//
//  TransactionTypeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/8/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TransactionSegmentControlView: UICollectionReusableView, ElementKind {
    
    static var kind: String = "transactionsegmentcontrol"
    
    enum SegmentType: Int {
        case rewards
        case you
        case connections
    }
    
    var didSelectSegmentIndex: ((SegmentType) -> Void)? = nil
    
    lazy var segmentControl: UISegmentedControl = {
        let rewardsAction = UIAction(title: "Rewards") { _ in
            self.didSelectSegmentIndex?(.rewards)
        }
        
        let youAction = UIAction(title: "You") { _ in
            self.didSelectSegmentIndex?(.you)
        }
        
        let connectionsAction = UIAction(title: "Connections") { _ in
            self.didSelectSegmentIndex?(.connections)
        }
        
        let control = UISegmentedControl(frame: .zero, actions: [rewardsAction, youAction, connectionsAction])
        control.selectedSegmentIndex = 0
        let attributes: [NSAttributedString.Key : Any] = [.font : FontType.small.font, .foregroundColor : ThemeColor.T1.color.withAlphaComponent(0.6)]
        control.setTitleTextAttributes(attributes, for: .normal)
        control.setTitleTextAttributes(attributes, for: .selected)
        control.setTitleTextAttributes(attributes, for: .highlighted)
        control.selectedSegmentTintColor = ThemeColor.B5.color.withAlphaComponent(0.1)
        control.selectedSegmentIndex = 1
        
        return control
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.segmentControl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.screenPadding.value
        let totalWidth = self.width - padding.doubled
        let segmentWidth = totalWidth * 0.33
        self.segmentControl.sizeToFit()
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 0)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 1)
        self.segmentControl.setWidth(segmentWidth, forSegmentAt: 2)

        self.segmentControl.width = self.width - padding.doubled
        self.segmentControl.centerOnX()
        self.segmentControl.pin(.bottom)
    }
}
