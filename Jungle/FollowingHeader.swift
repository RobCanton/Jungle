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

let distances = [1, 5, 10, 25, 50, 100, 200]


class FollowingHeader: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let cellIdentifier = "userPhotoCell"
    var itemSideLength:CGFloat!
    
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var topBanner: UIView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomHeader: UIView!
    @IBOutlet weak var bottomLabel: UILabel!

    @IBOutlet weak var longDivider: UIView!
    var topStories = [Story]()
    
    weak var stateRef:HomeStateController?

    
    @IBOutlet weak var stackTopAnchor: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        var distanceLabels = [String]()
//        for distance in distances {
//            distanceLabels.append("\(distance) km")
//        }
//        slider.addTarget(self,
//                         action: #selector(valueChanged(_:event:)),
//                         for: .valueChanged)
//        
//        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpInside)
//        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpOutside)
        
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
        collectionView.reloadData()
        collectionView.showsHorizontalScrollIndicator = false
        //collectionViewFollowing.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let layout2 = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = getItemSize()
        layout2.minimumInteritemSpacing = 0.0
        layout2.minimumLineSpacing = 0.0
        layout2.scrollDirection = .horizontal
        
        //resetStack()
    }
    
    var discoverLabel:UILabel?
    var section:Int = 0
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        //stackView.addArrangedSubview(gapView)

        stackView.addArrangedSubview(topBanner)
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(bottomHeader)
        
    
        topBanner.isHidden = false
        collectionView.isHidden = false
        bottomHeader.isHidden = false
        
        longDivider.isHidden = true
    }
    
    func removeStackView(view:UIView) {
        if stackView.arrangedSubviews.contains(view) {
            stackView.removeArrangedSubview(view)
        }
        view.isHidden = true
    }
    
    func setupStories(state: HomeStateController, section:Int) {
        self.section = section
        self.stateRef = state
        
        resetStack()

        switch section {
        case 0:
            //removeStackView(view: topBanner)
            topStories = state.followingStories
            topLabel.text = "FOLLOWING"
            bottomLabel.text = "POPULAR"
            
            if topStories.count == 0 {
                removeStackView(view: topBanner)
                removeStackView(view: collectionView)
            }
            
            if state.popularPosts.count == 0 {
                removeStackView(view: bottomHeader)
            }
            break
        case 1:
            topStories = state.nearbyPlaceStories
            topLabel.text = "NEARBY"
            bottomLabel.text = ""
            longDivider.isHidden = false
            
            if state.nearbyPlaceStories.count == 0  {
                removeStackView(view: bottomHeader)
                if state.nearbyPosts.count == 0 {
                    removeStackView(view: topBanner)
                }
            }
            break
        default:
            break
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

        if section == 1 && stateRef!.watchedFollowingStories.count > 0 && stateRef!.unseenFollowingStories.count > 0 {
            return CGSize(width: 12.0, height: itemSideLength * 1.25)
        }
        return CGSize.zero

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let state = self.stateRef else { return 0 }
        if self.section == 0 {
            if section == 0 {
                return state.unseenFollowingStories.count
            } else {
                return state.watchedFollowingStories.count
            }
        } else if self.section == 1 {
            return state.nearbyPlaceStories.count
        }
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
        if self.section == 0 {
            if indexPath.section == 0 {
                let story = stateRef!.unseenFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            } else {
                let story = stateRef!.watchedFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            }
        } else{
            
            let story = stateRef!.nearbyPlaceStories[indexPath.item]
            cell.setupCell(withPlaceStory: story, showDot: false)
        }
        
        return cell

    }
    


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.section == 0 {
            if indexPath.section == 0 {
                let story = stateRef!.unseenFollowingStories[indexPath.row]
                story.determineState()
                
                if story.state == .contentLoaded {
                    globalMainInterfaceProtocol?.presentBannerStory(presentationType: .homeHeader, stories: stateRef!.unseenFollowingStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
                } else {
                    story.downloadFirstItem()
                }
            } else {
                let story = stateRef!.watchedFollowingStories[indexPath.row]
                story.determineState()
                if story.state == .contentLoaded {
                    let dest = IndexPath(item: indexPath.item, section: 0)
                    globalMainInterfaceProtocol?.presentBannerStory( presentationType: .homeHeader, stories: stateRef!.watchedFollowingStories, destinationIndexPath: dest, initialIndexPath: indexPath)
                } else {
                    story.downloadFirstItem()
                }
            }
        } else {
            let story = stateRef!.nearbyPlaceStories[indexPath.row]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .homeNearbyHeader, stories: stateRef!.nearbyPlaceStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }
        }
        
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
    
}
