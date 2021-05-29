//
//  NoticeSupplier.swift
//  Ours
//
//  Created by Benji Dodgson on 5/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class NoticeSupplier {

    static let shared = NoticeSupplier()

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    private func subscribeToUpdates() {

    }
}
