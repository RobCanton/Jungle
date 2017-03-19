//
//  Utilities.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-17.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit




let imageCache = NSCache<NSString, UIImage>()

func loadImageUsingCacheWithURL(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {
    // Check for cached image
    if let cachedImage = imageCache.object(forKey: _url as NSString) {
        return completion(cachedImage, true)
    } else {
        downloadImageWithURLString(_url, completion: completion)
    }
}

func loadImageCheckingCache(withUrl _url:String, check:Int, completion: @escaping (_ image:UIImage?, _ fromCache:Bool, _ check:Int)->()) {
    // Check for cached image
    if let cachedImage = imageCache.object(forKey: _url as NSString) {
        return completion(cachedImage, true, check)
    } else {
        downloadImage(withUrl: _url, check: check, completion: completion)
    }
}

func downloadImageWithURLString(_ _url:String, completion: @escaping (_ image:UIImage?, _ fromCache:Bool)->()) {
    
    let url = URL(string: _url)
    
    URLSession.shared.dataTask(with: url!, completionHandler:
        { (data, response, error) in
            
            //error
            if error != nil {
                if error?._code == -999 {
                    return
                }
                //print(error?.code)
                return completion(nil, false)
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url as NSString)
                }
                
                let image = UIImage(data: data!)
                return completion(image!, false)
            }
            
    }).resume()
}

func downloadImage(withUrl _url:String, check:Int, completion: @escaping (_ image:UIImage?, _ fromCache:Bool, _ check:Int)->()) {
    
    let url = URL(string: _url)
    
    URLSession.shared.dataTask(with: url!, completionHandler:
        { (data, response, error) in
            
            //error
            if error != nil {
                if error?._code == -999 {
                    return
                }
                //print(error?.code)
                return completion(nil, false, check)
            }
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: _url as NSString)
                }
                
                let image = UIImage(data: data!)
                return completion(image!, false, check)
            }
            
    }).resume()
}




func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(width: newWidth,height: newHeight))
    image.draw(in: CGRect(x: 0,y: 0,width: newWidth,height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}

func cropImageToSquare(image: UIImage) -> UIImage? {
    var imageHeight = image.size.height
    var imageWidth = image.size.width
    
    if imageHeight > imageWidth {
        imageHeight = imageWidth
    }
    else {
        imageWidth = imageHeight
    }
    
    let size = CGSize(width: imageWidth, height: imageHeight)
    
    let refWidth : CGFloat = CGFloat(image.cgImage!.width)
    let refHeight : CGFloat = CGFloat(image.cgImage!.height)
    
    let x = (refWidth - size.width) / 2
    let y = (refHeight - size.height) / 2
    
    let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
    if let imageRef = image.cgImage!.cropping(to: cropRect) {
        return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
    }
    
    return nil
}

func getNumericShorthandString(_ number:Int) -> String {
    var str = "\(number)"
    
    if number >= 1000000 {
        let decimal = Double(number) / 1000000
        str = "\(roundToOneDecimal(decimal))M"
    } else if number >= 100000 {
        let decimal = Int(Double(number) / 1000)
        str = "\(decimal)K"
    } else if number >= 10000 {
        let decimal = Double(number) / 1000
        str = "\(roundToOneDecimal(decimal))K"
    } else if number >= 1000 {
        str.insert(",", at: str.index(str.startIndex, offsetBy: 1))
    }
    return str
}

func roundToOneDecimal(_ value:Double) -> Double {
    return Double(floor(value*10)/10)
}


