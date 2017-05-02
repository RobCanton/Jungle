//
//  FollowingHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

func compareUserStories(storiesA:[UserStory], storiesB:[UserStory]) {
    
}

class FollowingHeader: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    let cellIdentifier = "userPhotoCell"
    var collectionView:UICollectionView!
    var itemSideLength:CGFloat!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        itemSideLength = ((UIScreen.main.bounds.width - 4.0)/3.0) * 0.75
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height - 12), collectionViewLayout: layout)
        
        let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(collectionView)
        
    }
    
    var userStories = [UserStory]()
    
    var discoverLabel:UILabel?
    func setupStories(_userStories:[UserStory], myStory:UserStory?) {
        
        userStories = _userStories
        if myStory != nil {
            userStories.insert(myStory!, at: 0)
        }

        collectionView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return userStories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
        cell.setupFollowingCell(userStories[indexPath.item])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let story = userStories[indexPath.row]
        if story.state == .contentLoaded {
            globalMainRef?.presentUserStory(stories: userStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        } else {
            story.downloadStory()
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    
}
