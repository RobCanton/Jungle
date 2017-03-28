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

    
    var collectionView:UICollectionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        
        let nib = UINib(nibName: "UserStoryCollectionViewCell", bundle: nil)
        
        collectionView.register(nib, forCellWithReuseIdentifier: "userStoryCell")
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.reloadData()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(collectionView)

    }
    
    var userStories = [UserStory]()
    
    func setupStories(_userStories:[UserStory]) {
        

        userStories = _userStories
        
        collectionView.reloadData()

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return userStories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userStoryCell", for: indexPath) as! UserStoryCollectionViewCell
        cell.setupStoryInfo(story: userStories[indexPath.item])
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: self.frame.height * 0.85, height: self.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! UserStoryCollectionViewCell
        globalMainRef?.presentUserStory(stories: userStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    
}
