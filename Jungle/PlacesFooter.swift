//
//  PlacesFooter.swift
//  Jungle
//
//  Created by Robert Canton on 2017-06-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

class PlacesFooter: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    
    let cellIdentifier = "userPhotoCell"
    var itemSideLength:CGFloat!
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var topBanner: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomHeader: UIView!
    
    var nearbyPlaceStories = [LocationStory]() {
        didSet {
            print("nearbyPlaceStories: \(nearbyPlaceStories.count)")
        }
    }
    var nearbyPosts = [StoryItem]() {
        didSet {
            print("nearbyPosts: \(nearbyPlaceStories.count)")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        itemSideLength = ((UIScreen.main.bounds.width - 4.0)/3.0) * 0.72
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getItemSize()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        layout.scrollDirection = .horizontal
        
        collectionView.setCollectionViewLayout(layout, animated: false)
        
        let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        
        let headerNib = UINib(nibName: "EmptyCollectionHeader", bundle: nil)
        
        collectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeaderView")
        
        let headerNib3 = UINib(nibName: "GapCollectionHeader", bundle: nil)
        
        collectionView.register(headerNib3, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView")
        
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        //collectionViewFollowing.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let layout2 = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = getItemSize()
        layout2.minimumInteritemSpacing = 0.0
        layout2.minimumLineSpacing = 0.0
        layout2.scrollDirection = .horizontal
    }
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }

        stackView.addArrangedSubview(topBanner)
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(bottomHeader)
        
        topBanner.isHidden = false
        collectionView.isHidden = false
        bottomHeader.isHidden = false
        
    }
    
    func removeStackView(view:UIView) {
        if stackView.arrangedSubviews.contains(view) {
            stackView.removeArrangedSubview(view)
        }
        view.isHidden = true
    }
    
    func setupStories() {

        
        resetStack()

        if nearbyPlaceStories.count == 0  {
            removeStackView(view: bottomHeader)
            if nearbyPosts.count == 0 {
                removeStackView(view: topBanner)
            }
        }

        
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView", for: indexPath as IndexPath) as! GapCollectionHeader
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSize.zero
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        print("places count: \(nearbyPlaceStories.count)")
        return nearbyPlaceStories.count

        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
            
        let story = nearbyPlaceStories[indexPath.item]
        cell.setupCell(withPlaceStory: story, showDot: false)

        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let story = nearbyPlaceStories[indexPath.row]
        story.determineState()
        if story.state == .contentLoaded {
            globalMainInterfaceProtocol?.presentBannerStory(presentationType: .homeNearbyHeader, stories: nearbyPlaceStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        } else {
            story.downloadFirstItem()
        }

        
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
    
}
