//
//  ImageDisplayable.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

protocol ImageDisplayable {
    var image: UIImage? { get }
    var url: URL? { get }
    var imageFileObject: PFFileObject? { get }
 }

extension ImageDisplayable {

    var url: URL? {
        return nil 
    }

    var imageFileObject: PFFileObject? {
        return nil
    }
}
