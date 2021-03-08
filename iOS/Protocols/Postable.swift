//
//  Postable.swift
//  Ours
//
//  Created by Benji Dodgson on 2/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

protocol Postable {
    var author: User? { get set }
    var body: String? { get set }
    var priority: Int? { get set }
    var triggerDate: Date? { get set }
    var expirationDate: Date? { get set }
    var type: PostType? { get set }
    var file: PFFileObject? { get set }
    var attributes: [String: Any]? { get set }
}
