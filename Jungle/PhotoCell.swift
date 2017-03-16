//
//  PhotoCell.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-05.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var location:Location!
    
//    @IBOutlet weak var gradientView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 4.0
        self.clipsToBounds = true
        
        
        
        

    }

    func setupLocationCell (_ location:Location) {
        self.location = location
        nameLabel.text = location.getName()
        
        let lastPost = location.getStory().getPostKeys().first!
        let key = lastPost.0
        let time = lastPost.1
        
        let date = Date(timeIntervalSince1970: time/1000)
        self.timeLabel.text = date.timeStringSinceNow()
        
        self.imageView.image = nil
        
        let gradient = CAGradientLayer()
        gradient.frame = self.colorView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        self.colorView.layer.mask = gradient
        
        self.colorView.backgroundColor = UIColor.lightGray
        
        UploadService.getUpload(key: key, completion: { item in
            if item != nil {
                
                UploadService.retrieveImage(byKey: item!.getKey(), withUrl: item!.getDownloadUrl(), completion: { image, fromFile in
                    self.imageView.image = image
                    if !fromFile {
                        self.imageView.alpha = 0.0
                        UIView.animate(withDuration: 0.25, animations: {
                            self.imageView.alpha = 1.0
                        })
                    } else {
                        self.imageView.alpha = 1.0
                    }
                    
                    let avgColor = image!.areaAverage()
                    let saturatedColor = avgColor.modified(withAdditionalHue: 0, additionalSaturation: 0.3, additionalBrightness: 0.20)
                    self.colorView.backgroundColor = saturatedColor
                    
                    self.colorView.alpha = 0.6
                    self.nameLabel.applyShadow(radius: 2.0, opacity: 0.5, height: 1.0, shouldRasterize: true)
                    self.timeLabel.applyShadow(radius: 2.0, opacity: 0.5, height: 1.0, shouldRasterize: true)

                })
            }
        })
    }
    
    
    func fadeInInfo(animated:Bool) {
        if animated {
            self.colorView.alpha = 0.0
            self.nameLabel.alpha = 0.0
            self.timeLabel.alpha = 0.0
            UIView.animate(withDuration: 0.3, animations: {
                self.colorView.alpha = 0.6
                self.nameLabel.alpha = 1.0
                self.timeLabel.alpha = 1.0
            })
        } else{
            self.colorView.alpha = 0.6
            self.nameLabel.alpha = 1.0
            self.timeLabel.alpha = 1.0
        }
        
    }
    
    func fadeOutInfo() {
        self.colorView.alpha = 0.0
        self.nameLabel.alpha = 0.0
        self.timeLabel.alpha = 0.0
    }

}
