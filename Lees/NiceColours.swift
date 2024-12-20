//
//  NiceGray.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 16/12/2024.
//

import SwiftUI
import SwiftData
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIColor {
    static let niceGray = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            // Darker than before (originally 0.8, now 0.4)
            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .dark:
            // Even darker in dark mode (originally 0.2, now 0.1)
            return UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        @unknown default:
            return UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        }
    }
}

extension UIColor {
    static let niceBackground = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            return .secondarySystemBackground
        case .dark:
            return .systemBackground
        @unknown default:
            return .secondarySystemBackground
        }
    }
}



extension Color {
    static let progressGreen = Color(red: 0.3, green: 1.0, blue: 0.2)
}



func averageBrightness(from image: UIImage?) -> CGFloat {
    guard let image = image,
          let ciImage = CIImage(image: image) else { return 1.0 } // assume bright if no image
    
    let extent = ciImage.extent
    let filter = CIFilter.areaAverage()
    filter.inputImage = ciImage
    filter.extent = extent

    let context = CIContext()
    guard let outputImage = filter.outputImage else { return 1.0 }
    
    var bitmap = [UInt8](repeating: 0, count: 4)
    context.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBA8,
                   colorSpace: nil)
    
    let r = CGFloat(bitmap[0]) / 255.0
    let g = CGFloat(bitmap[1]) / 255.0
    let b = CGFloat(bitmap[2]) / 255.0
    
    // Simple approximation: average of RGB
    return (r + g + b) / 3.0
}


struct DynamicForegroundModifier: ViewModifier {
    let uiImage: UIImage?
    
    func body(content: Content) -> some View {
        let brightness = averageBrightness(from: uiImage)
        let textColor: Color = brightness < 0.5 ? .white : .black
        
        return content.foregroundColor(textColor)
    }
}

extension View {
    func dynamicForeground(uiImage: UIImage?) -> some View {
        self.modifier(DynamicForegroundModifier(uiImage: uiImage))
    }
}
