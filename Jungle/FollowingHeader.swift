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

    @IBOutlet weak var collectionViewFollowing: UICollectionView!
    @IBOutlet weak var collectionViewPeople: UICollectionView!
    
    
    let cellIdentifier = "userPhotoCell"
    var collectionView:UICollectionView!
    var collectionView2:UICollectionView!
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
        
        collectionViewFollowing.setCollectionViewLayout(layout, animated: false)
        let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionViewFollowing.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        collectionViewFollowing.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionViewFollowing.backgroundColor = UIColor.clear
        collectionViewFollowing.dataSource = self
        collectionViewFollowing.delegate = self
        collectionViewFollowing.reloadData()
        collectionViewFollowing.showsHorizontalScrollIndicator = false
        //collectionViewFollowing.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let layout2 = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = getItemSize()
        layout2.minimumInteritemSpacing = 0.0
        layout2.minimumLineSpacing = 0.0
        layout2.scrollDirection = .horizontal
        
        collectionViewPeople.setCollectionViewLayout(layout2, animated: false)
        //let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionViewPeople.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        collectionViewPeople.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionViewPeople.backgroundColor = UIColor.clear
        collectionViewPeople.dataSource = self
        collectionViewPeople.delegate = self
        collectionViewPeople.reloadData()
        collectionViewPeople.showsHorizontalScrollIndicator = false
        //collectionViewPeople.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //self.addSubview(collectionView)
        /*
        collectionView2 = UICollectionView(frame: CGRect(x: 0, y: self.bounds.height/2, width: self.bounds.width, height: self.bounds.height/2), collectionViewLayout: layout)
        
        let nib2 = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionView2.register(nib2, forCellWithReuseIdentifier: cellIdentifier)
        
        collectionView2.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionView2.backgroundColor = UIColor.clear
        collectionView2.dataSource = self
        collectionView2.delegate = self
        collectionView2.reloadData()
        collectionView2.showsHorizontalScrollIndicator = false
        collectionView2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //self.addSubview(collectionView2)
        
    */
        
    }
    
    var userStories = [UserStory]()
    var popularStories = [UserStory]()
    
    var discoverLabel:UILabel?
    func setupStories(_userStories:[UserStory], myStory:UserStory?, _popularStories:[UserStory]) {
        
        userStories = _userStories
        popularStories = _popularStories
        if myStory != nil {
            userStories.insert(myStory!, at: 0)
        }

        collectionViewFollowing.reloadData()
        collectionViewPeople.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        switch collectionView {
        case collectionViewFollowing:
            count = userStories.count
            break
        case collectionViewPeople:
            count = popularStories.count
            break
        default:
            break
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
        
        switch collectionView {
        case collectionViewFollowing:
            cell.setupFollowingCell(userStories[indexPath.row])
            break
        case collectionViewPeople:
            cell.setupFollowingCell(popularStories[indexPath.row])
            break
        default:
            break
        }
        
        return cell
    }
    


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
        let story = userStories[indexPath.row]
        if story.state == .contentLoaded {
            globalMainRef?.presentUserStory(stories: userStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        } else {
            story.downloadStory()
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        */
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    
}
