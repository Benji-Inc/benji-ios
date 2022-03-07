//
//  EmojiCategorySegmentControl.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/7/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCategorySegmentControl: UISegmentedControl {
    
    enum EmojiCategory: Int, CaseIterable {
        
        case smiles = 1
        case animals = 2
        case food = 3
        case travel = 4
        case activities = 5
        case objects = 6
        case symbols = 7
        case flags = 8
        
        var image: UIImage? {
            switch self {
            case .smiles:
                return UIImage(systemName: "face.smiling")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .animals:
                return UIImage(systemName: "hare")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .food:
                return UIImage(systemName: "cup.and.saucer")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .travel:
                return UIImage(systemName: "airplane")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .activities:
                return UIImage(systemName: "figure.walk")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .objects:
                return UIImage(systemName: "lightbulb")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
            case .symbols:
                return UIImage(systemName: "asterisk")
            case .flags:
                return UIImage(systemName: "flag")
            }
        }
    }
    
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
