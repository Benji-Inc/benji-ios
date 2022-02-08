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
        control.setTitleTextAttributes([.font: FontType.small.font], for: .normal)
        control.setTitleTextAttributes([.font: FontType.smallBold.font], for: .selected)
        control.setTitleTextAttributes([.font: FontType.smallBold.font], for: .highlighted)
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
        
        self.segmentControl.sizeToFit()
        self.segmentControl.centerOnXAndY()
    }
}
