//
//  InvitationUpsellCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InvitationUpsellCell: UICollectionViewCell, ConversationUIStateSettable {

    let button = ThemeButton()
    let label = ThemeLabel(font: .medium, textColor: .T3)
    let subTitle = ThemeLabel(font: .regular, textColor: .T3)
    let container = BaseView()
    
    var didSelectCreate: CompletionOptional = nil
    var heightMultiplier: CGFloat = 0.75

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
        
        self.container.set(backgroundColor: .D1)
        self.container.roundCorners()
        self.container.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .T2, text: "Add"))
        self.button.didSelect { [unowned self] in
            self.didSelectCreate?()
        }

        self.container.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.setText("Add your friends or family, to move to the front of the waitlist.")
        self.container.addSubview(self.subTitle)
        self.subTitle.alpha = 0.5
        self.subTitle.textAlignment = .center
        self.subTitle.setText("Larger groups get in first.")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.container.expandToSuperviewWidth()
        self.container.height = self.contentView.height * self.heightMultiplier
        self.container.pin(.top)
                
        let padding = Theme.ContentOffset.xtraLong.value.doubled
        
        self.button.height = Theme.buttonHeight
        self.button.width = self.container.width - padding
        self.button.centerOnX()
        self.button.pin(.bottom, offset: .xtraLong)
        
        self.label.setSize(withWidth: self.container.width - padding)
        self.label.centerOnX()
        self.label.center.y = self.container.halfHeight * 0.9
        
        self.subTitle.setSize(withWidth: self.container.width - padding)
        self.subTitle.centerOnX()
        self.subTitle.match(.top, to: .bottom, of: self.label, offset: .xtraLong)
    }
    
    func set(state: ConversationUIState) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.heightMultiplier = state == .write ? 0.35 : 0.75
            self.subTitle.alpha = state == .write ? 0.0 : 0.5
            self.setNeedsLayout()
        }
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        self.alpha = 1.0
    }
}
