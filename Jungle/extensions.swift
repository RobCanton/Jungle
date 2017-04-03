//
//  extensions.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func areaAverage() -> UIColor {
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        if #available(iOS 9.0, *) {
            // Get average color.
            let context = CIContext()
            let inputImage: CIImage = ciImage ?? CoreImage.CIImage(cgImage: cgImage!)
            let extent = inputImage.extent
            let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
            let filter = CIFilter(name: "CIAreaAverage", withInputParameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
            let outputImage = filter.outputImage!
            let outputExtent = outputImage.extent
            assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)
            
            // Render to bitmap.
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        } else {
            // Create 1x1 context that interpolates pixels when drawing to it.
            let context = CGContext(data: &bitmap, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            let inputImage = cgImage ?? CIContext().createCGImage(ciImage!, from: ciImage!.extent)
            
            // Render to bitmap.
            context.draw(inputImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: CGFloat(bitmap[3]) / 255.0)
        return result
    }
}

extension UIImageView {
    
    func loadImageAsync(_ url:String, completion:((_ fromCache:Bool)->())?) {
        loadImageUsingCacheWithURL(url, completion: { image, fromCache in
            self.image = image
            completion?(fromCache)
        })
    }
}

extension UIColor {
    
    func modified(withAdditionalHue hue: CGFloat, additionalSaturation: CGFloat, additionalBrightness: CGFloat) -> UIColor {
        
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0
        
        if self.getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentAlpha){
            return UIColor(hue: currentHue + hue,
                           saturation: currentSaturation + additionalSaturation,
                           brightness: currentBrigthness + additionalBrightness,
                           alpha: currentAlpha)
        } else {
            return self
        }
    }
}

extension UIView {
    func applyShadow(radius:CGFloat, opacity:Float, height:CGFloat, shouldRasterize:Bool) {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSize(width: 0, height: height)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shouldRasterize = shouldRasterize
    }
}

extension Date
{
    func timeStringSinceNow() -> String
    {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: self, to: Date())
        
        if components.day! >= 365 {
            return "\(components.day! / 365)y"
        }
        
        if components.day! >= 7 {
            return "\(components.day! / 7)w"
        }
        
        if components.day! > 0 {
            return "\(components.day!)d"
        }
        else if components.hour! > 0 {
            return "\(components.hour!)h"
        }
        else if components.minute! > 0 {
            return "\(components.minute!)m"
        }
        return "Now"
        //return "\(components.second)s"
    }
    
    func timeStringSinceNowWithAgo() -> String
    {
        let timeStr = timeStringSinceNow()
        if timeStr == "Now" {
            return timeStr
        }
        
        return "\(timeStr) ago"
    }
    
}

extension UILabel {
    
    public class func size(withText text: String, forWidth width: CGFloat, withFont font: UIFont) -> CGSize {
        let measurementLabel = UILabel()
        measurementLabel.font = font
        measurementLabel.text = text
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .byWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        measurementLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
        return measurementLabel.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    public class func size(withUsername username: String, andCaption caption:String, forWidth width: CGFloat) -> CGSize {
        let measurementLabel = UILabel()
        let str = "\(username) \(caption)"
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: username) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 16, weight: UIFontWeightBold),
                ]
            title.addAttributes(a, range: NSRange(location: index, length: username.characters.count))
        }
        
        
        measurementLabel.attributedText = title
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .byWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        measurementLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
        return measurementLabel.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    func styleProfileBlockText(count:Int, text:String, color:UIColor, color2:UIColor) {
        self.numberOfLines = 2
        self.textAlignment = .center
        var shortHand = getNumericShorthandString(count)
        
        let str = "\(shortHand)\n\(text)"
        let font = UIFont.systemFont(ofSize: 12)//(name: "AvenirNext-Regular", size: 12)
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : color,
            ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: shortHand) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 20.0, weight: UIFontWeightRegular),//UIFont(name: "AvenirNext-Medium", size: 16)!,
                NSForegroundColorAttributeName : color2
            ]
            title.addAttributes(a, range: NSRange(location: index, length: shortHand.characters.count))
        }
        
        
        self.attributedText = title
    }
    
    func styleFollowerText(count:Int, text:String, color:UIColor, color2:UIColor) {
        self.numberOfLines = 1
        self.textAlignment = .center
        var shortHand = getNumericShorthandString(count)
        
        let str = "\(shortHand) \(text)"
        let font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)//(name: "AvenirNext-Regular", size: 12)
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : color,
            ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        
        if let range = str.range(of: shortHand) {// .rangeOfString(countStr) {
            let index = str.distance(from: str.startIndex, to: range.lowerBound)//str.startIndex.distance(fromt:range.lowerBound)
            let a: [String: AnyObject] = [
                NSFontAttributeName : UIFont.systemFont(ofSize: 18, weight: UIFontWeightBold),//UIFont(name: "AvenirNext-Medium", size: 16)!,
                NSForegroundColorAttributeName : color2
            ]
            title.addAttributes(a, range: NSRange(location: index, length: shortHand.characters.count))
        }
        
        
        self.attributedText = title
    }
}
