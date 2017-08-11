//
//  HomeHeaderView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-03.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit


protocol HomeHeaderProtocol: class {
    func increaseRadiusTapped()
    func enableLocationTapped()
}


class HomeHeaderView: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource {

    var itemSideLength:CGFloat!
    let contentWidth = 100
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var followingCollectionView: UICollectionView!
    @IBOutlet weak var popularCollectionView: UICollectionView!
    @IBOutlet weak var placesCollectionView: UICollectionView!
    
    @IBOutlet weak var followingHeader: UIView!
    @IBOutlet weak var popularHeader: UIView!
    @IBOutlet weak var placesHeader: UIView!
    @IBOutlet weak var recentHeader: UIView!
    
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var placesLabel: UILabel!
    @IBOutlet weak var recentLabel: UILabel!
    
    @IBOutlet weak var locationSettingsView: UIView!
    @IBOutlet weak var locationSettingsButton: UIButton!
    @IBOutlet weak var locationSettingsBackground: UIView!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyButton: UIButton!
    @IBOutlet weak var emptyBackground: UIView!
    
    var state:HomeStateController!
    
    weak var delegate:HomeHeaderProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        itemSideLength = ((UIScreen.main.bounds.width - 4.0)/3.0) * 0.72
        let followingLayout = UICollectionViewFlowLayout()
        followingLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        followingLayout.itemSize = getStoryItemSize()
        followingLayout.minimumInteritemSpacing = 0.0
        followingLayout.minimumLineSpacing = 0.0
        followingLayout.scrollDirection = .horizontal
        
        followingCollectionView.setCollectionViewLayout(followingLayout, animated: false)
        
        let nib = UINib(nibName: "FollowingPhotoCell", bundle: nil)
        followingCollectionView.register(nib, forCellWithReuseIdentifier: "storyCell")
        
        let gapHeader = UINib(nibName: "GapCollectionHeader", bundle: nil)
        followingCollectionView.register(gapHeader, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView")
        
        followingCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        followingCollectionView.backgroundColor = UIColor.white
        followingCollectionView.showsHorizontalScrollIndicator = false
        
        
        let layout = popularCollectionView.collectionViewLayout as! TRMosaicHorizontalLayout
        layout.delegate = self
        
        let PhotoCell = UINib(nibName: "PhotoCell", bundle: nil)
        popularCollectionView.register(PhotoCell, forCellWithReuseIdentifier: "popularCell")
        
        let placesLayout = UICollectionViewFlowLayout()
        placesLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        placesLayout.itemSize = getStoryItemSize()
        placesLayout.minimumInteritemSpacing = 0.0
        placesLayout.minimumLineSpacing = 0.0
        placesLayout.scrollDirection = .horizontal
        
        placesCollectionView.setCollectionViewLayout(placesLayout, animated: false)
        
        placesCollectionView.register(nib, forCellWithReuseIdentifier: "storyCell")
        
        placesCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        placesCollectionView.backgroundColor = UIColor.white
        placesCollectionView.showsHorizontalScrollIndicator = false
        
        followingLabel.setKerning(withText: "FOLLOWING", 1.15)
        popularLabel.setKerning(withText: "POPULAR", 1.15)
        placesLabel.setKerning(withText: "PLACES", 1.15)
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
        
        stackView.addArrangedSubview(followingHeader)
        stackView.addArrangedSubview(followingCollectionView)
        stackView.addArrangedSubview(popularHeader)
        stackView.addArrangedSubview(popularCollectionView)
        stackView.addArrangedSubview(placesHeader)
        stackView.addArrangedSubview(placesCollectionView)
        stackView.addArrangedSubview(recentHeader)
        stackView.addArrangedSubview(locationSettingsView)
        stackView.addArrangedSubview(emptyView)
        
        
        followingHeader.isHidden = false
        followingCollectionView.isHidden = false
        popularHeader.isHidden = false
        popularCollectionView.isHidden = false
        placesHeader.isHidden = false
        placesCollectionView.isHidden = false
        recentHeader.isHidden = false
        locationSettingsView.isHidden = false
        emptyView.isHidden = false
        
        followingHeader.isUserInteractionEnabled = true
        followingCollectionView.isUserInteractionEnabled = true
        popularHeader.isUserInteractionEnabled = true
        popularCollectionView.isUserInteractionEnabled = true
        placesHeader.isUserInteractionEnabled = true
        placesCollectionView.isUserInteractionEnabled = true
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
        
        followingCollectionView.delegate = self
        followingCollectionView.dataSource = self
        followingCollectionView.reloadData()
        
        popularCollectionView.delegate = self
        popularCollectionView.dataSource = self
        popularCollectionView.reloadData()
        
        placesCollectionView.delegate = self
        placesCollectionView.dataSource = self
        placesCollectionView.reloadData()
        
        if state.unseenFollowingStories.count == 0 && state.watchedFollowingStories.count == 0 {
            removeStackView(view: followingHeader)
            removeStackView(view: followingCollectionView)
        }
        
        if state.nearbyCityStories.count == 0 {
            removeStackView(view: placesHeader)
            removeStackView(view: placesCollectionView)
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
        delegate?.increaseRadiusTapped()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "gapHeaderView", for: indexPath as IndexPath) as! GapCollectionHeader
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if collectionView === followingCollectionView && section == 1 && state.watchedFollowingStories.count > 0 && state.unseenFollowingStories.count > 0 {
            return CGSize(width: 12.0, height: itemSideLength * 1.25)
        }
        return CGSize.zero
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case followingCollectionView:
            if section == 0 {
                return state.unseenFollowingStories.count
            } else {
                return state.watchedFollowingStories.count
            }
        case popularCollectionView:
            return state.popularPosts.count
        case placesCollectionView:
            return state.nearbyCityStories.count
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        switch collectionView {
        case followingCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storyCell", for: indexPath) as! FollowingPhotoCell
            if indexPath.section == 0 {
                let story = state.unseenFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            } else {
                let story = state.watchedFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            }
            return cell
        case popularCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "popularCell", for: indexPath) as! PhotoCell
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            cell.setupCell(withPost: state.popularPosts[indexPath.row])
            cell.setCrownStatus(index: indexPath.item)
            cell.viewMore(false)
            return cell
        case placesCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storyCell", for: indexPath) as! FollowingPhotoCell
            let story = state.nearbyCityStories[indexPath.item]
            cell.setupCell(withCityStory: story)
            return cell
            
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        switch collectionView {
        case followingCollectionView:
            if indexPath.section == 0 {
                let story = state.unseenFollowingStories[indexPath.row]
                story.determineState()
                
                if story.state == .contentLoaded {
                    globalMainInterfaceProtocol?.presentBannerStory(presentationType: .following, stories: state.unseenFollowingStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
                } else {
                    story.downloadFirstItem()
                }
            } else {
                let story = state.watchedFollowingStories[indexPath.row]
                story.determineState()
                if story.state == .contentLoaded {
                    let dest = IndexPath(item: indexPath.item, section: 0)
                    globalMainInterfaceProtocol?.presentBannerStory( presentationType: .following, stories: state.watchedFollowingStories, destinationIndexPath: dest, initialIndexPath: indexPath)
                } else {
                    story.downloadFirstItem()
                }
            }
            break
        case popularCollectionView:
            
            let dest = IndexPath(item: indexPath.item, section: 0)
            globalMainInterfaceProtocol?.presentNearbyPost(presentationType: .popular, posts: state.popularPosts, destinationIndexPath: dest, initialIndexPath: indexPath)
            
            break
        case placesCollectionView:
            let story = state.nearbyCityStories[indexPath.row]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .places, stories: state.nearbyCityStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }

            break
        default:
            break
        }

        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionView === followingCollectionView ? 2 : 1
    }
    
    func getStoryItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
        
}

extension HomeHeaderView: TRMosaicHorizontalLayoutDelegate {

    
    func collectionView(_ collectionView:UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath:IndexPath) -> TRMosaicCellType {
        return indexPath.item == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicHorizontalLayout, insetAtSection:Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func widthForSmallMosaicCell() -> CGFloat {
        return popularCollectionView.bounds.width / 3
    }
}


