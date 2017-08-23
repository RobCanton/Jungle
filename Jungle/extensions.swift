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

extension UIColor {
    var rgbComponents:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (r,g,b,a)
        }
        return (0,0,0,0)
    }
    // hue, saturation, brightness and alpha components from UIColor**
    var hsbComponents:(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue:CGFloat = 0
        var saturation:CGFloat = 0
        var brightness:CGFloat = 0
        var alpha:CGFloat = 0
        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha){
            return (hue,saturation,brightness,alpha)
        }
        return (0,0,0,0)
    }
    var htmlRGBColor:String {
        return String(format: "#%02x%02x%02x", Int(rgbComponents.red * 255), Int(rgbComponents.green * 255),Int(rgbComponents.blue * 255))
    }
    var htmlRGBaColor:String {
        return String(format: "#%02x%02x%02x%02x", Int(rgbComponents.red * 255), Int(rgbComponents.green * 255),Int(rgbComponents.blue * 255),Int(rgbComponents.alpha * 255) )
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
    
    func cropToCircle() {
        self.layer.cornerRadius = self.frame.width/2
        self.clipsToBounds = true
    }
}

extension UIStackView {
    
    func remove(view:UIView) {
        if self.arrangedSubviews.contains(view) {
            self.removeArrangedSubview(view)
        }
        view.isHidden = true
        view.isUserInteractionEnabled = true
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

extension UITextView: UITextViewDelegate {
    
    // Placeholder text
    var placeholder: String? {
        
        get {
            // Get the placeholder text from the label
            var placeholderText: String?
            
            if let placeHolderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeHolderLabel.text
            }
            return placeholderText
        }
        
        set {
            // Store the placeholder text in the label
            var placeHolderLabel = self.viewWithTag(100) as! UILabel?
            if placeHolderLabel == nil {
                // Add placeholder label to text view
                self.addPlaceholderLabel(placeholderText: newValue!)
            }
            else {
                placeHolderLabel?.text = newValue
                placeHolderLabel?.sizeToFit()
            }
        }
    }
    
    
    func yo() {
        var placeHolderLabel = self.viewWithTag(100)
        
        if !self.hasText {
            // Get the placeholder label
            placeHolderLabel?.isHidden = false
        }
        else {
            placeHolderLabel?.isHidden = true
        }
    }
    
    
    
    // Add a placeholder label to the text view
    func addPlaceholderLabel(placeholderText: String) {
        
        // Create the label and set its properties
        var placeholderLabel = UILabel(frame: CGRect(x: 16, y: 10, width: self.bounds.width - 32, height: self.bounds.height - 20))
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        placeholderLabel.font = self.font
        placeholderLabel.textColor = UIColor.white
        placeholderLabel.alpha = 0.5
        placeholderLabel.tag = 100
        
        // Hide the label if there is text in the text view
        placeholderLabel.isHidden = self.text.characters.count > 0
        
        self.addSubview(placeholderLabel)
        self.delegate = self;
    }
    
}


extension UILabel {
    
    func setKerning(withText text:String, _ value:CGFloat) {
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSKernAttributeName, value: value, range: NSRange(location: 0, length: attributedString.length))
        self.attributedText = attributedString
    }
    
    func setUsernameWithBadge(username:String, badge:String, fontSize:CGFloat, fontWeight:CGFloat) {
        
        var str = ""
        if let badgeIcon = badges[badge] {
            str = "\(username) \(badgeIcon.icon)"
        } else {
            str = "\(username)"
        }
        
        let attributes: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize - 3.0, weight: fontWeight)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        let a: [String: AnyObject] = [
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize, weight: fontWeight)
            ]
        title.addAttributes(a, range: NSRange(location: 0, length: username.characters.count))

        
        self.attributedText = title
        
    }
    
    func setAnonymousName(anonName:String, color:UIColor, suffix:String, fontSize:CGFloat) {
        let str = "\(anonName) \(suffix)"
        var attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize - 2.0, weight: UIFontWeightLight)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        var a: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightSemibold),
            ]
        
        title.addAttributes(a, range: NSRange(location: 0, length: anonName.characters.count))
        
        self.attributedText = title
        
    }
    
    func setAnonymousName(anonName:String, color:UIColor, suffix:String, largeFont:CGFloat, smallFont:CGFloat, fontSize:CGFloat) {
        let str = "\(anonName) \(suffix)"
        var attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize - 2.0, weight: smallFont)
        ]
        
        let title = NSMutableAttributedString(string: str, attributes: attributes) //1
        var a: [String: AnyObject] = [
            NSForegroundColorAttributeName: color,
            NSFontAttributeName : UIFont.systemFont(ofSize: fontSize, weight: largeFont),
            ]
        
        title.addAttributes(a, range: NSRange(location: 0, length: anonName.characters.count))
        
        self.attributedText = title
        
    }
    

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
    
    public class func size(withText text: String, forHeight height: CGFloat, withFont font: UIFont) -> CGSize {
        let measurementLabel = UILabel()
        measurementLabel.font = font
        measurementLabel.text = text
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .byWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        measurementLabel.heightAnchor.constraint(equalToConstant: height).isActive = true
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

extension UITextView {
    
    func fitHeightToContent() {
        let fixedWidth = self.frame.size.width
        self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = self.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = self.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        self.frame = newFrame;
    }
}


func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }
    
    if ((cString.characters.count) != 6) {
        return UIColor.gray
    }
    
    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

func darkerColorForColor(color: UIColor) -> UIColor {
    
    var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
    
    if color.getRed(&r, green: &g, blue: &b, alpha: &a){
        return UIColor(red: max(r - 0.16, 0.0), green: max(g - 0.16, 0.0), blue: max(b - 0.16, 0.0), alpha: a)
    }
    
    return color
}

extension UIButton {
    
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0,y: 0.0,width: 1.0,height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func setBackgroundColor(color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color: color), for: state)
    }
    
    func setGradient(colorA:UIColor, colorB: UIColor) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = [
            colorA.cgColor,
            colorB.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        self.layer.insertSublayer(gradient, at: 0)
    }
}



