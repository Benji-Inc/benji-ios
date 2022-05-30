//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import UIKit

@MainActor
public protocol Presentable: AnyObject {

    typealias DismissableVC = UIViewController & Dismissable

    func toPresentable() -> DismissableVC
    func removeFromParent()
}
