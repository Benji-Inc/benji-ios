//
//  new_Coordinator.swift
//  new_Coordinator
//
//  Created by Martin Young on 8/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol new_CoordinatorType: AnyObject {

    var router: Router { get }
    var parentCoordinator: new_CoordinatorType? { set get }
    var childCoordinator: new_CoordinatorType? { get }
    var furthestChild: new_CoordinatorType { get }

    func addChildAndStart<ChildResult>(_ coordinator: new_Coordinator<ChildResult>,
                                       finishedHandler: @escaping (ChildResult) -> Void)
    func removeChild()
}

class new_Coordinator<Result>: new_CoordinatorType {

    let router: Router
    var deepLink: DeepLinkable?

    private var onFinishedFlow: ((Result) -> Void)?

    weak var parentCoordinator: new_CoordinatorType?
    private(set) var childCoordinator: new_CoordinatorType?
    var furthestChild: new_CoordinatorType {
        if let child = self.childCoordinator {
            return child.furthestChild
        }
        return self
    }

    init(router: Router, deepLink: DeepLinkable?) {
        self.router = router
        self.deepLink = deepLink
    }

    /// Called by the addChildAndStart method. Override this method to check state requirements for coordinator flow.
    func start() { }

    /// Can be used to change a coordinators deepLink and restart its flow
    final func start(with deepLink: DeepLinkable?) {
        self.deepLink = deepLink
        self.start()
    }

    func addChildAndStart<ChildResult>(_ coordinator: new_Coordinator<ChildResult>,
                                       finishedHandler: @escaping (ChildResult) -> Void) {
        // If we already have a child coordinator, log a warning. While this isn't ideal, it helps
        // prevent apps from getting locked up due to a coordinator not finishing or being presented
        // properly.
        if self.childCoordinator != nil {
            print("WARNING!!!!! ATTEMPTING TO ADD CHILD COORDINATOR \(coordinator)"
                + " TO COORDINATOR \(self) THAT ALREADY HAS ONE \(self.childCoordinator!)")
        }

        // Set the parent coordinator of the the previous child coordinator to nil
        self.childCoordinator?.parentCoordinator = nil

        coordinator.parentCoordinator = self
        self.childCoordinator = coordinator

        // Assign the finish handler before calling start in case the coordinator finishes immediately
        coordinator.onFinishedFlow = finishedHandler
        coordinator.start()
    }

    func removeChild() {
        self.childCoordinator = nil
    }

    func removeFromParent() {
        if self.parentCoordinator?.childCoordinator === self {
            self.parentCoordinator?.removeChild()
        }
    }

    func finishFlow(with result: Result) {
        self.removeFromParent()
        self.onFinishedFlow?(result)
    }
}

class new_PresentableCoordinator<Result>: Coordinator<Result>, Presentable {

    func toPresentable() -> DismissableVC {
        fatalError("toPresentable not implemented in \(self)")
    }
}
