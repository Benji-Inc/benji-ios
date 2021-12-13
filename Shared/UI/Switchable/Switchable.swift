//
//  Switchable.swift
//  Benji
//
//  Created by Benji Dodgson on 1/16/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol Switchable: Equatable {
    var viewController: UIViewController & Sizeable { get }
}
