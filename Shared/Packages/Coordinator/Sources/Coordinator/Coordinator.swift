//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import Combine

@MainActor
public class Coordinator<Result>: NSObject, CoordinatorType {

    public let router: Router
    public var deepLink: DeepLinkable?

    private var onFinishedFlow: ((Result) -> Void)?

    weak var parentCoordinator: CoordinatorType?
    private(set) var childCoordinator: CoordinatorType?

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

    func addChildAndStart<ChildResult>(_ coordinator: Coordinator<ChildResult>,
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

