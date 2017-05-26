//
//  FollowingHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

import TGPControls
func compareUserStories(storiesA:[UserStory], storiesB:[UserStory]) {
    
}

let distances = [1, 5, 10, 25, 50, 100, 200]


class FollowingHeader: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionViewFollowing: UICollectionView!
    @IBOutlet weak var collectionViewPeople: UICollectionView!
    
    let cellIdentifier = "userPhotoCell"
    var collectionView:UICollectionView!
    var collectionView2:UICollectionView!
    var itemSideLength:CGFloat!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var settingsView: UIView!

    @IBOutlet weak var sliderLabels: TGPCamelLabels!
    @IBOutlet weak var slider: TGPDiscreteSlider!
    
    @IBOutlet weak var followingBanner: UIView!
    @IBOutlet weak var storiesBanner: UIView!
    @IBOutlet weak var placesBanner: UIView!
    
    var myStory:UserStory!
    var topStories = [UserStory]()
    var bottomStories = [UserStory]()
    
    weak var stateRef:HomeStateController?
    var mode:SortedBy = .Popular
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        var distanceLabels = [String]()
        for distance in distances {
            distanceLabels.append("\(distance) km")
        }
        sliderLabels.names = distanceLabels
        
        slider.ticksListener = sliderLabels
        
        slider.addTarget(self,
                         action: #selector(valueChanged(_:event:)),
                         for: .valueChanged)
        
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpOutside)
        
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
        
         let headerNib = UINib(nibName: "EmptyCollectionHeader", bundle: nil)
        
        collectionViewFollowing.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeaderView")
        
        
        let headerNib3 = UINib(nibName: "GapCollectionHeader", bundle: nil)
        
        collectionViewFollowing.register(headerNib3, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView")
        
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
        
        let headerNib2 = UINib(nibName: "EmptyCollectionHeader", bundle: nil)
        
        collectionViewPeople.register(headerNib2, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeaderView")
        
        collectionViewPeople.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionViewPeople.backgroundColor = UIColor.clear
        collectionViewPeople.dataSource = self
        collectionViewPeople.delegate = self
        collectionViewPeople.reloadData()
        collectionViewPeople.showsHorizontalScrollIndicator = false
        //collectionViewPeople.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        print("LOADED YO")
        
        //resetStack()
    }
    
    
    
    var discoverLabel:UILabel?
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        
        stackView.addArrangedSubview(settingsView)
        stackView.addArrangedSubview(followingBanner)
        stackView.addArrangedSubview(collectionViewFollowing)
        stackView.addArrangedSubview(storiesBanner)
        stackView.addArrangedSubview(collectionViewPeople)
        stackView.addArrangedSubview(placesBanner)
        
        settingsView.isHidden = false
        followingBanner.isHidden = false
        collectionViewFollowing.isHidden = false
        storiesBanner.isHidden = false
        collectionViewPeople.isHidden = false
        placesBanner.isHidden = false
    }
    
    func removeStackView(view:UIView) {
        if stackView.arrangedSubviews.contains(view) {
            stackView.removeArrangedSubview(view)
        }
        view.isHidden = true
    }
    
    func setupStories(mode:SortedBy, state: HomeStateController) {
        self.mode = mode
        self.stateRef = state
        
        resetStack()
        self.myStory = state.myStory
        
        switch mode {
        case .Popular:
            topStories = state.followingStories
            bottomStories = state.popularUserStories
            removeStackView(view: settingsView)
            if state.popularPlaceStories.count == 0 {
                removeStackView(view: placesBanner)
            }
            break
        case .Nearby:
            topStories = state.nearbyFollowingStories
            bottomStories = state.nearbyUserStories
            if state.nearbyPlaceStories.count == 0 {
                removeStackView(view: placesBanner)
            }
            break
        case .Recent:
            topStories = state.followingStories
            removeStackView(view: settingsView)
            bottomStories = state.recentUserStories
            if state.recentPlaceStories.count == 0 {
                removeStackView(view: placesBanner)
            }
            break
        }
        
        if topStories.count == 0 && myStory.count  == 0 {
            removeStackView(view: followingBanner)
            removeStackView(view: collectionViewFollowing)
        }
        
        if bottomStories.count == 0 {
            removeStackView(view: storiesBanner)
            removeStackView(view: collectionViewPeople)
        }
        
        collectionViewFollowing.reloadData()
        collectionViewPeople.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            if indexPath.section == 0 && myStory.count == 0 {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "emptyHeaderView", for: indexPath as IndexPath) as! EmptyCollectionHeader
                return view
            } else if indexPath.section == 1 && myStory.count > 0 {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView", for: indexPath as IndexPath) as! GapCollectionHeader
                return view
            }
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch collectionView {
        case collectionViewFollowing:
            if section == 0 && myStory.count == 0 {
                return getItemSize()
            } else if section == 1 && myStory.count > 0 && topStories.count > 0 {
                return CGSize(width: 12.0, height: itemSideLength * 1.3333)
            }
            return CGSize.zero
        default:
            return CGSize.zero
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var sections = 0
        switch collectionView {
        case collectionViewFollowing:
            sections = myStory.count > 0 ? 2 : 1
            break
        case collectionViewPeople:
            sections = 1
            break
        default:
            break
        }
        return sections
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        switch collectionView {
        case collectionViewFollowing:
            count = myStory.count > 0 && section == 0 ? 1 : topStories.count
            break
        case collectionViewPeople:
            count = bottomStories.count
            break
        default:
            break
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == collectionViewFollowing {
            var story:UserStory!
            if indexPath.section == 0 && myStory.count > 0 {
                story = myStory
            } else {
                story = topStories[indexPath.row]
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
            cell.setupFollowingCell(story, showDot: true)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
            cell.setupFollowingCell(bottomStories[indexPath.row], showDot: false)
            return cell
        }
    }
    


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destinationPath = IndexPath(item: indexPath.item, section: 0)
        switch collectionView {
        case collectionViewFollowing:
            var story:UserStory!
            var stories:[UserStory]!
            
            if indexPath.section == 0 && myStory.count > 0 {
                story = myStory
                stories = [myStory]
            } else {
                story = topStories[indexPath.row]
                stories = topStories
            }
            
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentUserStory(stories: stories, destinationIndexPath: destinationPath, initialIndexPath: indexPath, hasMyStory: true)
            } else {
                story.downloadStory()
            }
            break
        case collectionViewPeople:
            let story = bottomStories[indexPath.row]
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentPublicUserStory(stories: bottomStories, destinationIndexPath: destinationPath, initialIndexPath: indexPath)
            } else {
                story.downloadStory()
            }
            break
        default:
            break
        }
        collectionView.deselectItem(at: indexPath, animated: true)

    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    func stopped(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(sender.value)
        sliderLabels.value = UInt(value)
        let distance = distances[value]
        print("DISTANCE SELECTED: \(distance)")
        LocationService.sharedInstance.radius = distance
        LocationService.sharedInstance.requestNearbyLocations()
    }
    
    func valueChanged(_ sender: TGPDiscreteSlider, event:UIEvent) {
        sliderLabels.value = UInt(sender.value)
    }
    
    
}
