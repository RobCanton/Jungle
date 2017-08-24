//
//  HomeHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-03.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit


protocol HomeHeaderProtocol: class {
    func showSortOptions()
    func enableLocationTapped()
}


class HomeHeaderView: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    var itemSideLength:CGFloat!
    let contentWidth = 100
    
    @IBOutlet weak var topGapView: UIView!
    @IBOutlet weak var stackView: UIStackView!

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var recentHeader: UIView!
    @IBOutlet weak var recentLabel: UILabel!
    @IBOutlet weak var locationSettingsView: UIView!
    @IBOutlet weak var locationSettingsButton: UIButton!
    @IBOutlet weak var locationSettingsBackground: UIView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyButton: UIButton!
    @IBOutlet weak var emptyBackground: UIView!
    @IBOutlet weak var empyStackView: UIStackView!
    @IBOutlet weak var emptyActivityIndicator: UIActivityIndicatorView!

    var state:HomeStateController!
    
    weak var delegate:HomeHeaderProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        itemSideLength = ((UIScreen.main.bounds.width - 4.0)/3.0) * 0.74

        let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "storyCell")
        
        let gapHeader = UINib(nibName: "GapCollectionHeader", bundle: nil)
        collectionView.register(gapHeader, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView")
        
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = getStoryItemSize()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        layout.scrollDirection = .horizontal
        
        collectionView.setCollectionViewLayout(layout, animated: false)
        
        collectionView.register(nib, forCellWithReuseIdentifier: "storyCell")
        
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsHorizontalScrollIndicator = false
        
        recentLabel.setKerning(withText: "RECENT", 1.15)
        
        locationSettingsButton.layer.cornerRadius = locationSettingsButton.bounds.height / 2
        locationSettingsButton.clipsToBounds = true
        
        let gradient = CAGradientLayer()
        gradient.frame = locationSettingsButton.bounds
        gradient.colors = [
            lightAccentColor.cgColor,
            darkAccentColor.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        locationSettingsButton.layer.insertSublayer(gradient, at: 0)
        
        locationSettingsBackground.layer.cornerRadius = 8.0
        locationSettingsBackground.clipsToBounds = true
        
        emptyButton.layer.cornerRadius = locationSettingsButton.bounds.height / 2
        emptyButton.clipsToBounds = true
        
        let gradient2 = CAGradientLayer()
        gradient2.frame = emptyButton.bounds
        gradient2.colors = [
            lightAccentColor.cgColor,
            darkAccentColor.cgColor
        ]
        gradient2.locations = [0.0, 1.0]
        gradient2.startPoint = CGPoint(x: 0, y: 0)
        gradient2.endPoint = CGPoint(x: 1, y: 0)
        emptyButton.layer.insertSublayer(gradient2, at: 0)
        
        emptyBackground.layer.cornerRadius = 8.0
        emptyBackground.clipsToBounds = true

    }
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }
        stackView.addArrangedSubview(topGapView)
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(recentHeader)
        stackView.addArrangedSubview(locationSettingsView)
        stackView.addArrangedSubview(emptyView)
        
        collectionView.isHidden = false
        recentHeader.isHidden = false
        locationSettingsView.isHidden = false
        emptyView.isHidden = false
        
        collectionView.isUserInteractionEnabled = true
        recentHeader.isUserInteractionEnabled = true
        locationSettingsView.isUserInteractionEnabled = true
        emptyView.isUserInteractionEnabled = true
    }
    
    func removeStackView(view:UIView) {
        if stackView.arrangedSubviews.contains(view) {
            stackView.removeArrangedSubview(view)
        }
        view.isHidden = true
        view.isUserInteractionEnabled = true
    }
    
    func setup(_state: HomeStateController, isLocationEnabled:Bool) {
        self.state = _state
        
        resetStack()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()

        if !state.hasHeaderPosts {
            removeStackView(view: topGapView)
            removeStackView(view: collectionView)
            removeStackView(view: recentHeader)
        }
        
        if isLocationEnabled {
            removeStackView(view: locationSettingsView)
            
            if state.nearbyPosts.count > 0 {
                removeStackView(view: emptyView)
            }
        } else {
            removeStackView(view: emptyView)
        }
        
    }
    
    @IBAction func enableLocationTapped(_ sender: Any) {
        delegate?.enableLocationTapped()
    }
    
    @IBAction func increaseRadius(_ sender: Any) {
        delegate?.showSortOptions()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView", for: indexPath as IndexPath) as! GapCollectionHeader
            return view
        }
//
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let size = CGSize(width: 8.0, height: itemSideLength * 1.25)
        switch section {
        case 0:
            return CGSize.zero
        case 1:
            return state.unseenFollowingStories.count > 0 && state.nearbyCityStories.count > 0 ? size : CGSize.zero
        case 2:
            return state.nearbyCityStories.count > 0 && state.watchedFollowingStories.count > 0 ? size : CGSize.zero
        default:
            return CGSize.zero
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return state.unseenFollowingStories.count
        case 1:
            return state.nearbyCityStories.count
        case 2:
            return state.watchedFollowingStories.count
        default:
            return 0
        }
        

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storyCell", for: indexPath) as! FollowingPhotoCell
        
        switch indexPath.section {
        case 0:
            let story = state.unseenFollowingStories[indexPath.item]
            cell.setupCell(withUserStory: story, showDot: false)
            cell.alpha = 1.0
            break
        case 1:
            let story = state.nearbyCityStories[indexPath.item]
            cell.setupCell(withCityStory: story)
            cell.alpha = 1.0
            break
        case 2:
            let story = state.watchedFollowingStories[indexPath.item]
            cell.setupCell(withUserStory: story, showDot: false)
            cell.alpha = 0.60
            break
        default:
            break
        }
        
        return cell
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch indexPath.section {
        case 0:
            let story = state.unseenFollowingStories[indexPath.item]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .places, stories: state.unseenFollowingStories, destinationIndexPath: IndexPath(item: indexPath.item, section: 0), initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }
            break
        case 1:
            let story = state.nearbyCityStories[indexPath.item]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .places, stories: state.nearbyCityStories, destinationIndexPath: IndexPath(item: indexPath.item, section: 0), initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }
            break
        case 2:
            let story = state.watchedFollowingStories[indexPath.item]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .places, stories: state.watchedFollowingStories, destinationIndexPath: IndexPath(item: indexPath.item, section: 0), initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }
            break
        default:
            break
        }
        
    }


    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func getStoryItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
    
    func setEmptyViewLoading(_ isLoading:Bool) {
        emptyBackground.isHidden = isLoading
        
        if isLoading {
            emptyActivityIndicator.startAnimating()
        } else {
            emptyActivityIndicator.stopAnimating()
        }
    }
        
}


