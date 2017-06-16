//
//  FollowingHeader.swift
//  Jungle
//
//  Created by Robert Canton on 2017-03-20.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

import TGPControls
import TwicketSegmentedControl
func compareUserStories(storiesA:[UserStory], storiesB:[UserStory]) {
    
}

let distances = [1, 5, 10, 25, 50, 100, 200]


class FollowingHeader: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionViewFollowing: UICollectionView!
    
    let cellIdentifier = "userPhotoCell"
    var itemSideLength:CGFloat!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var settingsView: UIView!

    @IBOutlet weak var slider: TGPDiscreteSlider!
    
    @IBOutlet weak var followingBanner: UIView!
    @IBOutlet weak var storiesBanner: UIView!

    var topStories = [Story]()
    
    weak var stateRef:HomeStateController?
    var mode:SortedBy = .Popular
    
    weak var sliderLabels:TGPCamelLabels?
    weak var segmentedControl:TwicketSegmentedControl?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        var distanceLabels = [String]()
        for distance in distances {
            distanceLabels.append("\(distance) km")
        }
        slider.addTarget(self,
                         action: #selector(valueChanged(_:event:)),
                         for: .valueChanged)
        
        slider.addTarget(self, action: #selector(down), for: .touchDown)
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(stopped(_:event:)), for: .touchUpOutside)
        
        itemSideLength = ((UIScreen.main.bounds.width - 4.0)/3.0) * 0.78
        
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
        
        settingsView.isHidden = false
        followingBanner.isHidden = false
        collectionViewFollowing.isHidden = false
        storiesBanner.isHidden = false
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
        
        switch mode {
        case .Popular:
            removeStackView(view: settingsView)
            removeStackView(view: followingBanner)
            removeStackView(view: collectionViewFollowing)
            removeStackView(view: storiesBanner)
            break
        case .Nearby:
            topStories = state.nearbyPlaceStories
            if topStories.count == 0 {
                removeStackView(view: storiesBanner)
                removeStackView(view: followingBanner)
                removeStackView(view: collectionViewFollowing)
            }
            removeStackView(view: followingBanner)
            break
        case .Recent:
            removeStackView(view: settingsView)
            removeStackView(view: followingBanner)
            removeStackView(view: collectionViewFollowing)
            removeStackView(view: storiesBanner)
            break
        }

        
    
        
        collectionViewFollowing.reloadData()
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topStories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let story = topStories[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
        if let locationStory = story as? LocationStory {
            cell.setupCell(withPlaceStory: locationStory, showDot: false)
        }
        //cell.setupFollowingCell(story, showDot: true)
        return cell

    }
    


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let story = topStories[indexPath.row]
        story.determineState()
        if story.state == .contentLoaded {
            //globalMainInterfaceProtocol?.presentUserStory(userStories: state.followingStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            globalMainInterfaceProtocol?.presentBannerStory(stories: topStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
        } else {
            story.downloadFirstItem()
        }
        collectionView.deselectItem(at: indexPath, animated: true)

    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.3333)
    }
    
    var animateShow = false
    
    func down() {
        animateShow = true
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
            self.segmentedControl?.alpha = 0.0
        }) { _ in
            if self.animateShow {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: {
                    self.sliderLabels?.alpha = 1.0
                })
            }
        }
    }
    
    func stopped(_ sender: TGPDiscreteSlider, event:UIEvent) {
        let value = Int(sender.value)
        sliderLabels?.value = UInt(value)
        let distance = distances[value]
        LocationService.sharedInstance.radius = distance
        LocationService.sharedInstance.requestNearbyLocations()
        animateShow = false
        UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseIn, animations: {
            self.sliderLabels?.alpha = 0.0
        }) { _ in
            if !self.animateShow {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                    self.segmentedControl?.alpha = 1.0
                })
            }
        }
        
    }
    
    func valueChanged(_ sender: TGPDiscreteSlider, event:UIEvent) {
        sliderLabels?.value = UInt(sender.value)
    }
    
    
}
