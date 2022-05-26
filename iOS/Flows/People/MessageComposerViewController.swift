//
//  MessageComposerViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import MessageUI
import Coordinator

class MessageComposerViewController: MFMessageComposeViewController, Dismissable {
    var dismissHandlers: [DismissHandler] = []

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
}
