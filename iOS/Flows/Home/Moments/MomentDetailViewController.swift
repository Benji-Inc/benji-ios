//
//  MomentDetailViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentDetailViewController: ViewController {

     private let moment: Moment

     init(with moment: Moment) {
         self.moment = moment
         super.init()
     }

     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
 }
