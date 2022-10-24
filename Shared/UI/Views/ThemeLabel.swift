//
//  ThemeLabel.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Localization
 
/// A custom label that automatically applies font, color and kerning attributes to text set through the standard text member variable.
class ThemeLabel: UILabel {

    override var text: String? {
        get { return super.text }
        set {
            guard let string = newValue else {
                // No need to apply attributes to a nil string.
                super.text = nil
                return
            }
            self.setTextWithAttributes(string)
        }
    }

    /// Kerning to be applied to all text in this label. If an attributed string is set manually, there is no guarantee that this variable
    /// will be accurate, but setting it will update kerning on all text in the label.
    var kerning: CGFloat {
        didSet {
            // Reload the current text with the new kerning value
            guard let text = self.text else { return }
            self.setTextWithAttributes(text)
        }
    }

    var stringCasing: StringCasing {
        didSet {
            guard let text = self.text else { return }
            self.setTextWithAttributes(text)
        }
    }

    /// The string attributes to apply to any text. This reflects the label's assigned font and font color.
    private var defaultAttributes: [NSAttributedString.Key : Any] {
        let font = self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let textColor = self.textColor ?? ThemeColor.white.color

        return [.font : font,
                .foregroundColor : textColor,
                .kern : self.kerning]
    }

    // MARK: Lifecycle

    init(frame: CGRect = .zero,
         font: FontType,
         textColor: ThemeColor = .white) {
        
        self.kerning = font.kern
        self.stringCasing = .unchanged

        super.init(frame: frame)

        self.font = font.font
        self.textColor = textColor.color.resolvedColor(with: self.traitCollection)
        self.initializeLabel()
    }

    required init?(coder: NSCoder) {
        self.kerning = 0
        self.stringCasing = .unchanged

        super.init(coder: coder)

        self.initializeLabel()
    }

    func initializeLabel() {
        self.lineBreakMode = .byWordWrapping
        self.numberOfLines = 0
    }

    // MARK: Setters

    func setText(_ localizedText: Localized?) {
        guard let localizedText = localizedText else {
            self.text = nil
            return
        }
        self.text = localized(localizedText)
    }

    func setFont(_ fontType: FontType) {
        self.font = fontType.font
        self.kerning = fontType.kern
    }

    func setTextColor(_ textColor: ThemeColor) {
        self.textColor = textColor.color.resolvedColor(with: self.traitCollection)
    }
    
    func resetToDefaultAttributes() {
        self.setTextWithAttributes(self.text ?? "")
    }

    func add(attributes: [NSAttributedString.Key : Any], to text: String) {
        guard let existingText = self.attributedText else { return }
        
        let lowercased = existingText.string.lowercased()
        
        guard let range = lowercased.range(of: text.lowercased()) else { return }
        
        self.add(attributes: attributes, at: lowercased.nsRange(from: range))
    }
    
    func add(attributes: [NSAttributedString.Key : Any], at range: NSRange) {
        guard let existingText = self.attributedText else { return }

        let attributedString = NSMutableAttributedString(existingText)
        attributedString.addAttributes(attributes, range: range)
        super.attributedText = attributedString
    }

    private func setTextWithAttributes(_ newText: String) {
        let string = self.stringCasing.format(string: newText)

        // Create an attributed string and add attributes to the entire range.
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttributes(self.defaultAttributes, range: NSRange(location: 0,
                                                                       length: attributedString.length))

        super.attributedText = attributedString
    }
}

extension ThemeLabel {

    func setSize(withWidth width: CGFloat, height: CGFloat = .greatestFiniteMagnitude) {
        self.size = self.getSize(withWidth: width, height: height)
    }

    func getSize(withWidth width: CGFloat, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        guard let text = self.text,
              !text.isEmpty,
              let attText = self.attributedText else { return .zero }

        var attributes = attText.attributes(at: 0,
                                            longestEffectiveRange: nil,
                                            in: NSRange(location: 0, length: attText.length))
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            let mutableStyle = NSMutableParagraphStyle()
            mutableStyle.setParagraphStyle(paragraphStyle)
            mutableStyle.lineBreakMode = .byWordWrapping
            attributes[.paragraphStyle] = mutableStyle
        }

        let maxSize = CGSize(width: width, height: height)

        let labelSize: CGSize = text.boundingRect(with: maxSize,
                                                  options: .usesLineFragmentOrigin,
                                                  attributes: attributes,
                                                  context: nil).size

        return labelSize
    }
}
