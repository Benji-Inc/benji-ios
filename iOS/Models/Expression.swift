//
//  Expression.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct Expression {
    var author: String? 
    var imageURL: URL?
    var emojiString: String?
    var emotionCounts: [Emotion: Int] = [:]
}
