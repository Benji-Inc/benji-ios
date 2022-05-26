//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import Combine

@MainActor
open class Coordinator<Result>: NSObject, CoordinatorType {

    public let router: CoordinatorRouter

    private var onFinishedFlow: ((Result) -> Void)?

    public weak var parentCoordinator: CoordinatorType?
    public var childCoordinator: CoordinatorType?

    public init(router: CoordinatorRouter) {
        self.router = router
    }

    /// Called by the addChildAndStart method. Override this method to check state requirements for coordinator flow.
    open func start() { }

    public func addChildAndStart<ChildResult>(_ coordinator: Coordinator<ChildResult>,
                                       finishedHandler: @escaping (ChildResult) -> Void) {
        // If we already have a child coordinator, log a warning. While this isn't ideal, it helps
        // prevent apps from getting locked up due to a coordinator not finishing or being presented
        // properly.
        if !self.childCoordinator.isNil {
            let warning = """
                    WARNING!!!!! ATTEMPTING TO ADD CHILD COORDINATOR \(coordinator) \
                    TO COORDINATOR \(self) THAT ALREADY HAS ONE \(self.childCoordinator!)
                    """
            print(warning)
        }

        // Set the parent coordinator of the the previous child coordinator to nil
        self.childCoordinator?.parentCoordinator = nil

        coordinator.parentCoordinator = self
        self.childCoordinator = coordinator

        // Assign the finish handler before calling start in case the coordinator finishes immediately
        coordinator.onFinishedFlow = finishedHandler
        coordinator.start()
    }

    public func removeChild() {
        self.childCoordinator = nil
    }

    public func removeFromParent() {
        if self.parentCoordinator?.childCoordinator === self {
            self.parentCoordinator?.removeChild()
        }
    }

    public func finishFlow(with result: Result) {
        self.removeFromParent()
        self.onFinishedFlow?(result)
    }
}

