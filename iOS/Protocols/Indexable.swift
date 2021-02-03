//
//  Indexable.swift
//  Ours
//
//  Created by Benji Dodgson on 1/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol Indexable: AnyObject {
    var indexPath: IndexPath? { get set }
}
