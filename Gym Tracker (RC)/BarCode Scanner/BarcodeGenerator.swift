import UIKit
import CDCodabarView

struct BarcodeGenerator {
    // Shared instance for convenient access.
    static let shared = BarcodeGenerator()
    
    /// Generates a Codabar barcode image from the provided input.
    /// - Parameter input: The Codabar string (e.g., "A12345B").
    /// - Returns: A UIImage of the generated barcode, or nil if generation fails.
    func generateCodabarBarcode(from input: String) -> UIImage? {
        let barcodeWidth: CGFloat = 300
        let barcodeHeight: CGFloat = 100
        let barcodeSize = CGSize(width: barcodeWidth, height: barcodeHeight)
        
        let codabarView = CDCodabarView()
        codabarView.code = input
        codabarView.barColor = .black
        codabarView.hideCode = true
        codabarView.font = UIFont(name: "AvenirNext-Regular", size: 15.0) ?? UIFont.systemFont(ofSize: 15)
        codabarView.backgroundColor = .clear
        codabarView.frame = CGRect(origin: .zero, size: barcodeSize)
        codabarView.layer.cornerRadius = 0
        codabarView.layer.masksToBounds = false
        
        UIGraphicsBeginImageContextWithOptions(barcodeSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: barcodeSize))
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        codabarView.layer.render(in: context)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
