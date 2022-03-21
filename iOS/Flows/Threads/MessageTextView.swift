//
//  MessageTextView.swift
//  Benji
//
//  Created by Benji Dodgson on 7/1/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class MessageTextView: TextView {

    override func initializeViews() {
        super.initializeViews()
        
        self.isEditable = false
        self.isScrollEnabled = false
        self.isSelectable = true

        self.textContainerInset.left = 0
        self.textContainerInset.right = 0
        self.textContainerInset.top = 0
        self.textContainerInset.bottom = 0
    }

    func setText(with message: Messageable) {
        switch message.kind {
        case .text(_):
            self.setText(message.kind.text)
        case .attributedText(_):
            break
        case .photo(photo: let photo, body: let body):
            guard let url = photo.url else { return }
            self.loadImage(with: url, with: body)
        case .video(video: let video, body: let body):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .link(_):
            break
        }
        
    }

    private var loadImageTask: Task<Void, Never>?

    private func loadImage(with url: URL, with body: String) {
        self.loadImageTask?.cancel()

        self.loadImageTask = Task { [weak self] in
            guard !Task.isCancelled else { return }

            self?.text = body

            guard let data: Data = try? await URLSession.shared.dataTask(with: url).0 else { return }

            guard !Task.isCancelled else { return }

            // Contruct the image from the returned data
            guard let image = UIImage(data: data) else { return }

            // Create an image attachment and insert it into the text.
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.setImageHeight(height: 100)


            let fullText = NSMutableAttributedString(self!.attributedText)

            let imageString = NSAttributedString(attachment: attachment)
            fullText.append(NSAttributedString(string: "\n"))
            fullText.append(imageString)

            self!.attributedText = fullText
        }
    }

    // Allows us to interact with links if they exist or pass the touch to the next receiver if they do not
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top

        // Find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < self.textStorage.length {
            // Check if character is a link and handle normally
            if self.textStorage.attribute(NSAttributedString.Key.link,
                                          at: characterIndex,
                                          effectiveRange: nil) != nil {
                return self
            }
        }

        // Return nil to pass touch to next receiver
        return nil
    }
}

extension NSTextAttachment {

    func setImageHeight(height: CGFloat) {
        guard let image = self.image else { return }

        let ratio = image.size.width / image.size.height

        self.bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: ratio * height, height: height)
    }
}
