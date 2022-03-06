//
//  ContextCueCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class ContextCueCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ContextCue
    
    var currentItem: ContextCue?
    
    let container = BaseView()
    let emojiLabel = ThemeLabel(font: .contextCues)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.container)
        self.container.set(backgroundColor: .B0)
        self.container.layer.borderColor = ThemeColor.white.color.withAlphaComponent(0.3).cgColor
        self.container.layer.borderWidth = 1
        self.container.layer.cornerRadius = Theme.cornerRadius
        self.container.layer.masksToBounds = true
        
        self.container.addSubview(self.emojiLabel)
        self.emojiLabel.textAlignment = .center
    }
    
    func configure(with item: ContextCue) {
        Task {
            guard let updated = try? await item.retrieveDataIfNeeded() else { return }
            self.emojiLabel.setText(self.getEmojiText(for: updated))
            self.layoutNow()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.emojiLabel.setSize(withWidth: self.contentView.width)
        self.container.size = CGSize(width: self.emojiLabel.width + Theme.ContentOffset.standard.value.doubled,
                                     height: self.contentView.height)
        self.container.centerOnXAndY()
        self.emojiLabel.centerOnXAndY()
    }
    
    override func update(isSelected: Bool) {
        super.update(isSelected: isSelected)
    }
    
    private func getEmojiText(for contextCue: ContextCue) -> Localized {
        
        var emojiText = ""
        let max: Int = 3
        for (index, value) in contextCue.emojis.enumerated() {
            if index <= max - 1 {
                emojiText.append(contentsOf: value)
            }
        }
        
        if contextCue.emojis.count > max {
            let amount = contextCue.emojis.count - max
            emojiText.append(contentsOf: " +\(amount)")
        }
        
        return emojiText
    }
}
