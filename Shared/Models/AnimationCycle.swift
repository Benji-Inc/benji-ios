//
//  AnimationCycle.swift
//  Benji
//
//  Created by Benji Dodgson on 2/9/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

struct AnimationCycle {
    var inFromPosition: AnimationPosition?
    var outToPosition: AnimationPosition?
    var shouldConcatenate: Bool
    var scrollToIndexPath: IndexPath?
    var scrollPosition: UICollectionView.ScrollPosition = .centeredHorizontally
    var scrollToOffset: CGPoint? = nil
}
