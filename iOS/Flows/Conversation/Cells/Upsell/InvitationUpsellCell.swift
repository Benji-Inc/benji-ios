//
//  InvitationUpsellCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InvitationUpsellCell: UICollectionViewCell, ConversationUIStateSettable {

    let content = UpsellContentView()
    
    var didSelectAddPeople: CompletionOptional = nil
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
        self.contentView.addSubview(self.content)
        
        self.content.configure(with: "Who do you want to Jibber with?",
                               subtitle: "Up to 10 in a group chat.",
                               buttonTitle: "Choose People")
        self.content.button.didSelect { [unowned self] in
            self.didSelectAddPeople?()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.content.expandToSuperviewWidth()
        self.content.height = self.contentView.height * self.heightMultiplier
        self.content.pin(.top)
    }
    
    func set(state: ConversationUIState) {
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.heightMultiplier = state == .write ? 0.35 : 0.75
            self.content.subTitle.alpha = state == .write ? 0.0 : 0.5
            self.setNeedsLayout()
        }
    }
}
