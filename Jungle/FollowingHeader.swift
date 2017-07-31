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


protocol HomeHeaderProtocol: class {
    func emptyHeaderTapped()
}



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
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyGrayView: UIView!
    weak var stateRef:HomeStateController?

    weak var delegate:HomeHeaderProtocol?
    
    @IBOutlet weak var stackTopAnchor: NSLayoutConstraint!
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
        collectionView.reloadData()
        collectionView.showsHorizontalScrollIndicator = false
        //collectionViewFollowing.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let layout2 = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = getItemSize()
        layout2.minimumInteritemSpacing = 0.0
        layout2.minimumLineSpacing = 0.0
        layout2.scrollDirection = .horizontal
        
        emptyGrayView.layer.cornerRadius = 8.0
        emptyGrayView.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(emptyHeaderTapped))
        emptyGrayView.addGestureRecognizer(tap)
        
        
        //resetStack()
    }
    
    func emptyHeaderTapped() {
        delegate?.emptyHeaderTapped()
    }
    
    
    var discoverLabel:UILabel?
    var sectionRef:Int = 0
    
    func resetStack() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }

        stackView.addArrangedSubview(topBanner)
        stackView.addArrangedSubview(collectionView)
        stackView.addArrangedSubview(bottomHeader)
        stackView.addArrangedSubview(emptyView)
        
    
        topBanner.isHidden = false
        collectionView.isHidden = false
        bottomHeader.isHidden = false
        emptyView.isHidden = false
        
        topBanner.isUserInteractionEnabled = true
        collectionView.isUserInteractionEnabled = true
        bottomHeader.isUserInteractionEnabled = true
        emptyGrayView.isUserInteractionEnabled = true
        
        longDivider.isHidden = true
    }
    
    func removeStackView(view:UIView) {
        if stackView.arrangedSubviews.contains(view) {
            stackView.removeArrangedSubview(view)
        }
        view.isHidden = true
        view.isUserInteractionEnabled = true
    }
    
    func setupStories(state: HomeStateController, section:Int) {
        print("Self: \(self.sectionRef) Section: \(section)")
        
        self.sectionRef = section
        self.stateRef = state
        
        resetStack()

        switch sectionRef {
        case 0:
            removeStackView(view: emptyView)
            topLabel.setKerning(withText: "FOLLOWING", 1.15)
            bottomLabel.setKerning(withText: "POPULAR", 1.15)
            
            if state.unseenFollowingStories.count == 0 && state.watchedFollowingStories.count == 0 {
                removeStackView(view: topBanner)
                removeStackView(view: collectionView)
            }
            
            if state.popularPosts.count == 0 {
                removeStackView(view: bottomHeader)
            }
            
            break
        case 1:

            topLabel.setKerning(withText: "PLACES", 1.15)
            bottomLabel.setKerning(withText: "RECENT", 1.15)
            
            if state.nearbyPosts.count > 0 {
                removeStackView(view: emptyView)
            }
            
            if state.nearbyCityStories.count == 0  {
                removeStackView(view: topBanner)
                removeStackView(view: collectionView)
                if state.nearbyPosts.count == 0 {
                    //removeStackView(view: topBanner)
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

        if sectionRef == 0 && section == 1 && stateRef!.watchedFollowingStories.count > 0 && stateRef!.unseenFollowingStories.count > 0 {
            return CGSize(width: 12.0, height: itemSideLength * 1.25)
        }
        return CGSize.zero

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if sectionRef == 0 {
            return 2
        }
        return 1
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let state = self.stateRef else {
            print("No state: \(sectionRef)")
            
            return 0 }
        if self.sectionRef == 0 {
            if section == 0 {
                return state.unseenFollowingStories.count
            } else {
                return state.watchedFollowingStories.count
            }
        } else if self.sectionRef == 1 {
            print("nearbyCityStories \(state.nearbyCityStories.count)")
            return state.nearbyCityStories.count
        }
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! FollowingPhotoCell
        if self.sectionRef == 0 {
            if indexPath.section == 0 {
                let story = stateRef!.unseenFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            } else {
                let story = stateRef!.watchedFollowingStories[indexPath.item]
                cell.setupCell(withUserStory: story, showDot: false)
            }
        } else{
            
            let story = stateRef!.nearbyCityStories[indexPath.item]
            cell.setupCell(withCityStory: story)
        }
        
        return cell

    }
    


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return getItemSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.sectionRef == 0 {
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
            let story = stateRef!.nearbyCityStories[indexPath.row]
            story.determineState()
            if story.state == .contentLoaded {
                globalMainInterfaceProtocol?.presentBannerStory(presentationType: .homeNearbyHeader, stories: stateRef!.nearbyCityStories, destinationIndexPath: indexPath, initialIndexPath: indexPath)
            } else {
                story.downloadFirstItem()
            }
        }
        
    }
    
    func getItemSize() -> CGSize {
        return CGSize(width: itemSideLength, height: itemSideLength * 1.25)
    }
    
}
