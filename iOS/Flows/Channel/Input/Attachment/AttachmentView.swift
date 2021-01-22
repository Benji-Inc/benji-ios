//
//  AttachmentView.swift
//  Ours
//
//  Created by Benji Dodgson on 1/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class AttachmentView: View {

    private let imageView = DisplayableImageView()
    private var cancellables = Set<AnyCancellable>()

    @Published var attachement: Attachement?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.translatesAutoresizingMaskIntoConstraints = false

        self.set(backgroundColor: .red)

        self.addSubview(self.imageView)
        self.imageView.imageView.contentMode = .scaleToFill
        self.imageView.clipsToBounds = true
    }

    func configure(with item: Attachement?) {
        guard let attachement = item else { return }

        self.attachement = attachement
        AttachmentsManager.shared.getImage(for: attachement, size: self.size)
            .mainSink { (image, _) in
                self.imageView.displayable = image
            }.store(in: &self.cancellables)
    }
}
