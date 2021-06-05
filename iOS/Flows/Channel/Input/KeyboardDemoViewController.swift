//
//  MessagingDemoViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class KeyboardDemoViewController: ViewController {

    let scrollView = UIScrollView()
    let pagingIndicator = UIPageControl()

    enum DemoType {

        case send
        case sendAlert
        case cursor

        var instruction: Localized {
            switch self {
            case .send:
                return ""
            case .sendAlert:
                return ""
            case .cursor:
                return ""
            }
        }

        var animation: MicroAnimation {
            switch self {
            case .send:
                return .checkbox
            case .sendAlert:
                return .checkbox
            case .cursor:
                return .checkbox
            }
        }
    }

    override func loadView() {
        self.view = self.scrollView
    }

    func load(demos: [DemoType]) {

    }

    func play() {

    }
}
