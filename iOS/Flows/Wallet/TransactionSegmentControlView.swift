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
        case you
        case connections
    }
    
    var didSelectSegmentIndex: ((SegmentType) -> Void)? = nil
    
    lazy var segmentControl: UISegmentedControl = {
        let youAction = UIAction(title: "You") { _ in
            self.didSelectSegmentIndex?(.you)
        }
        
        let connectionsAction = UIAction(title: "Connections") { _ in
            self.didSelectSegmentIndex?(.connections)
        }
        
        let control = UISegmentedControl(frame: .zero, actions: [youAction, connectionsAction])
        control.selectedSegmentIndex = 0
        let attributes: [NSAttributedString.Key : Any] = [.font : FontType.small.font, .foregroundColor : ThemeColor.T1.color.withAlphaComponent(0.6)]
        control.setTitleTextAttributes(attributes, for: .normal)
        control.setTitleTextAttributes(attributes, for: .selected)
        control.setTitleTextAttributes(attributes, for: .highlighted)
        control.selectedSegmentTintColor = ThemeColor.white.color.withAlphaComponent(0.1)
        
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
        
        self.segmentControl.sizeToFit()
        self.segmentControl.setWidth(self.halfWidth - padding, forSegmentAt: 0)
        self.segmentControl.setWidth(self.halfWidth - padding, forSegmentAt: 1)
        self.segmentControl.width = self.width - padding.doubled
        self.segmentControl.centerOnXAndY()
    }
}
