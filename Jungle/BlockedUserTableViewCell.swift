//
//  BlockedUserTableViewCell.swift
//  Jungle
//
//  Created by Robert Canton on 2017-07-12.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

protocol BlockedUserCellProtocol:class {
    func blockUser(_ id:String, _ isAnon:Bool)
}

class BlockedUserTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var blockButton: UIButton!
    
    weak var delegate:BlockedUserCellProtocol?
    
    var isAnon = false
    var id:String = ""
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        userImageView.cropToCircle()
        
        blockButton.layer.cornerRadius = 4.0
        blockButton.clipsToBounds = true
        blockButton.layer.borderWidth = 1.0
        blockButton.isHidden = false
        blockButton.layer.borderColor = UIColor.clear.cgColor
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setAnonymousUser(_ aid:String, _ timestamp: Double) {
        let date = Date(timeIntervalSince1970: timestamp/1000)
        userImageView.image = UIImage(named: "private_dark")
        usernameLabel.text = "Anonymous User"
        timeLabel.text = "Blocked \(date.timeStringSinceNowWithAgo())"
        
        
    }
    
    func setUser(_ uid:String) {
        UserService.getUser(uid) { user in
            if user == nil { return }
            self.userImageView.loadImageAsync(user!.imageURL, completion: nil)
            self.usernameLabel.text = user!.username
            self.timeLabel.text = user!.fullname
        }
    }
    
    @IBAction func handleButton(_ sender: UIButton) {
        print("HANDLE!")
        delegate?.blockUser(id, isAnon)
    }
}
