//
//  InvitationUpsellCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InvitationUpsellCell: UICollectionViewCell, ConversationUIStateSettable {

    let gradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight], startPoint: .topLeft, endPoint: .bottomRight)
    let button = ThemeButton()
    let label = ThemeLabel(font: .medium, textColor: .T3)
    let subTitle = ThemeLabel(font: .regular, textColor: .T3)
    let container = BaseView()
    
    var didSelectCreate: CompletionOptional = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.container)
        
        self.container.layer.insertSublayer(self.gradientLayer, at: 0)
        self.container.addSubview(self.button)
        self.button.set(style: .normal(color: .white, text: "Create Circle"))
        self.button.didSelect { [unowned self] in
            self.didSelectCreate?()
        }
        
        self.container.addSubview(self.label)
        self.label.setText("Invite friends or family to join you on Jibber, to move to the front of the waitlist.")
        self.container.addSubview(self.subTitle)
        self.subTitle.setText("Up to 10 in a group.\nLarger groups get in first.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.container.expandToSuperviewSize()
        self.gradientLayer.frame = self.container.bounds
        
        let padding = Theme.ContentOffset.long.value.doubled
        
        self.button.height = Theme.buttonHeight
        self.button.width = self.container.width - padding
        self.button.centerOnX()
        
        self.label.setSize(withWidth: self.container.width - padding)
        self.label.centerOnX()
        self.label.center.y = self.container.halfHeight * 0.9
        
        self.subTitle.setSize(withWidth: self.container.width - padding)
        self.subTitle.centerOnX()
        self.subTitle.match(.top, to: .bottom, of: self.label, offset: .xtraLong)
    }
    
    func set(state: ConversationUIState) {
        //self.topOffset = state == .write ? 142 : 291
        self.setNeedsLayout()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        self.alpha = 1.0
    }
}
