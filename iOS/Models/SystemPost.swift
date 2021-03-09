//
//  SystemPost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class SystemPost: Postable {

    var author: User?
    var body: String?
    var priority: Int
    var triggerDate: Date?
    var expirationDate: Date?
    var type: PostType
    var file: PFFileObject?
    var attributes: [String: Any]?
    var duration: Int

    init(author: User,
         body: String,
         triggerDate: Date?,
         expirationDate: Date?,
         type: PostType,
         file: PFFileObject?,
         attributes: [String: Any]?,
         priority: Int,
         duration: Int) {

        self.author = author
        self.body = body
        self.triggerDate = triggerDate
        self.expirationDate = expirationDate
        self.type = type
        self.file = file
        self.attributes = attributes
        self.priority = priority
        self.duration = duration
    }
}
