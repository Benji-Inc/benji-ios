//
//  CaptionView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CaptionView: View {

    let label = Label(font: .regularBold, textColor: .background4)
    let captionLabel = Label(font: .smallBold)
    private var cancellables = Set<AnyCancellable>()

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.addSubview(self.captionLabel)
    }

    func setText(for post: Postable) -> Future<Void, Error> {
        return Future { promise in
            post.author?.retrieveDataIfNeeded()
                .mainSink(receiveValue: { user in
                    self.label.setText(user.handle)
                    self.captionLabel.setText(post.body)
                    promise(.success(()))
                }).store(in: &self.cancellables)
        }
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        self.width = width
        
        self.label.setSize(withWidth: width)
        self.label.pin(.top)
        self.label.pin(.left)

        self.captionLabel.setSize(withWidth: width)
        self.captionLabel.match(.top, to: .bottom, of: self.label, offset: 4)
        self.captionLabel.pin(.left)

        return self.captionLabel.bottom
    }
}
