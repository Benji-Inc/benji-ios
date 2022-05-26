//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation

@MainActor
protocol CoordinatorType: AnyObject {

    var router: Router { get }
    var parentCoordinator: CoordinatorType? { set get }
    var childCoordinator: CoordinatorType? { get }

    func addChildAndStart<ChildResult>(_ coordinator: Coordinator<ChildResult>,
                                       finishedHandler: @escaping (ChildResult) -> Void)
    func removeChild()
}

extension CoordinatorType {

    var furthestChild: CoordinatorType {
        if let child = self.childCoordinator {
            return child.furthestChild
        }
        return self
    }
}
