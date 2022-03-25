//
//  EmojiCategorySegmentControl.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCategorySegmentControl: UISegmentedControl {
    
    var didSelectCategory: ((EmojiCategory) -> Void)? = nil
    
    init() {
        
        super.init(frame: .zero)
        
        EmojiCategory.allCases.forEach { category in
            let action = UIAction(image: category.image) { _ in
                self.didSelectCategory?(category)
            }
            self.insertSegment(action: action, at: category.rawValue, animated: false)
        }

        self.selectedSegmentTintColor = ThemeColor.B5.color.withAlphaComponent(0.1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
