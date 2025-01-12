// BarcodeGenerator.swift
// Gym Tracker
//
// Created by Jack on 1/13/25.
//

import UIKit
import CDCodabarView

struct BarcodeGenerator {
    /// Generates a UIImage of a Codabar barcode using CDCodabarView.
    /// - Parameter input: The Codabar string to encode (e.g., "A12345B").
    /// - Returns: A UIImage representing the Codabar barcode, or nil if generation fails.
    func generateCodabarBarcode(from input: String) -> UIImage? {
        // Initialize CDCodabarView with desired properties
        let codabarView = CDCodabarView()
        codabarView.code = input
        codabarView.barColor = .black // Set bar color to black
        codabarView.textColor = .clear // Hide the code text
        codabarView.padding = 15 // Increase padding
        codabarView.hideCode = true // Ensure the code text is hidden
        codabarView.font = UIFont(name: "AvenirNext-Regular", size: 15.0) ?? UIFont.systemFont(ofSize: 15)
        
        // Set the frame size based on desired barcode dimensions
        let width: CGFloat = 300
        let height: CGFloat = 100
        codabarView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        codabarView.backgroundColor = .white

        // Remove rounded corners (default appearance)
        codabarView.layer.cornerRadius = 0
        codabarView.layer.masksToBounds = false

        // Render CDCodabarView into a UIImage
        UIGraphicsBeginImageContextWithOptions(codabarView.bounds.size, codabarView.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        codabarView.layer.render(in: context)
        let barcodeImage = UIGraphicsGetImageFromCurrentImageContext()
        
        return barcodeImage
    }
}
