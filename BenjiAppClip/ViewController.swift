//
//  ViewController.swift
//  BenjiAppClip
//
//  Created by Benji Dodgson on 12/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        if let activity = self.userActivity {
            print(activity)
        }
    }
}

