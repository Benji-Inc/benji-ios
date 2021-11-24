//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    var threadLayout: ThreadCollectionViewLayout? {
        return self.collectionViewLayout as? ThreadCollectionViewLayout
    }

    init() {
        super.init(layout: ThreadCollectionViewLayout())

        self.showsVerticalScrollIndicator = false
        self.keyboardDismissMode = .interactive
        self.automaticallyAdjustsScrollIndicatorInsets = true 
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        guard let dropZoneFrame = self.threadLayout?.getDropZoneFrame() else { return .zero }

        return self.convert(dropZoneFrame, to: targetView)
    }
}
