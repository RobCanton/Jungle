//
//  TRMosaicLayout.swift
//  Pods
//
//  Created by Vincent Le on 7/1/16.
//
//

import UIKit


public protocol TRMosaicHorizontalLayoutDelegate {
    
    func collectionView(_ collectionView:UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath:IndexPath) -> TRMosaicCellType
    
    func collectionView(_ collectionView:UICollectionView, layout collectionViewLayout: TRMosaicHorizontalLayout, insetAtSection:Int) -> UIEdgeInsets
    
    func widthForSmallMosaicCell() -> CGFloat
}

open class TRMosaicHorizontalLayout: UICollectionViewLayout {
    
    
    open var delegate:TRMosaicHorizontalLayoutDelegate!
    
    var rows = TRMosaicRows()
    
    var cachedCellLayoutAttributes = [IndexPath:UICollectionViewLayoutAttributes]()
    
    let numberOfRowsInSection = 2
    
    var contentHeight:CGFloat {
        get { return collectionView!.bounds.size.height }
    }
    
    // MARK: UICollectionViewLayout Implementation
    
    override open func prepare() {
        super.prepare()
        
        resetLayoutState()
        configureMosaicLayout()
    }
    
    /**
     Iterates throught all items in section and
     creates new layouts for each item as a mosaic cell
     */
    func configureMosaicLayout() {
        // Queue containing cells that have yet to be added due to column constraints
        var smallCellIndexPathBuffer = [IndexPath]()
        
        var lastBigCellOnLeftSide = false
        // Loops through all items in the first section, this layout has only one section
        for cellIndex in 0..<collectionView!.numberOfItems(inSection: 0) {
            
            (lastBigCellOnLeftSide, smallCellIndexPathBuffer) = createCellLayout(withIndexPath: cellIndex,
                                                                                 bigCellSide: lastBigCellOnLeftSide,
                                                                                 cellBuffer: smallCellIndexPathBuffer)
        }
        
        if !smallCellIndexPathBuffer.isEmpty {
            addSmallCellLayout(atIndexPath: smallCellIndexPathBuffer[0], atRow: indexOfShortestRow())
            smallCellIndexPathBuffer.removeAll()
        }
    }
    
    /**
     Creates new layout for the cell at specified index path
     
     - parameter index:       index path of cell
     - parameter bigCellSide: specifies which side to place big cell
     - parameter cellBuffer:  buffer containing small cell
     
     - returns: tuple containing cellSide and cellBuffer, only one of which will be mutated
     */
    func createCellLayout(withIndexPath index: Int, bigCellSide: Bool, cellBuffer: [IndexPath]) -> (Bool, [IndexPath]) {
        let cellIndexPath = IndexPath(item: index, section: 0)
        let cellType:TRMosaicCellType = mosaicCellType(index: cellIndexPath)
        
        var newBuffer = cellBuffer
        var newSide = bigCellSide
        
        if cellType == .big {
            newSide = createBigCellLayout(withIndexPath: cellIndexPath, cellSide: bigCellSide)
        } else if cellType == .small {
            newBuffer = createSmallCellLayout(withIndexPath: cellIndexPath, buffer: newBuffer)
        }
        return (newSide, newBuffer)
    }
    
    /**
     Creates new layout for the big cell at specified index path
     - returns: returns new cell side
     */
    func createBigCellLayout(withIndexPath indexPath:IndexPath, cellSide: Bool) -> Bool {
        addBigCellLayout(atIndexPath: indexPath, atRow: cellSide ? 1 : 0)
        return !cellSide
    }
    
    /**
     Creates new layout for the small cell at specified index path
     - returns: returns new cell buffer
     */
    func createSmallCellLayout(withIndexPath indexPath:IndexPath, buffer: [IndexPath]) -> [IndexPath] {
        var newBuffer = buffer
        newBuffer.append(indexPath)
        if newBuffer.count >= 2 {
            let row = indexOfShortestRow()
            
            addSmallCellLayout(atIndexPath: newBuffer[0], atRow: row)
            addSmallCellLayout(atIndexPath: newBuffer[1], atRow: row)
            
            newBuffer.removeAll()
        }
        return newBuffer
    }
    
    /**
     Returns the entire content view of the collection view
     */
    override open var collectionViewContentSize: CGSize {
        get {
            
            let width = rows.smallestRow.rowWidth
            return CGSize(width: width, height: contentHeight)
        }
    }
    
    /**
     Returns all layout attributes within the given rectangle
     */
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesInRect = [UICollectionViewLayoutAttributes]()
        cachedCellLayoutAttributes.forEach {
            if rect.intersects($1.frame) {
                attributesInRect.append($1)
            }
        }
        return attributesInRect
    }
    
    /**
     Returns all layout attributes for the current indexPath
     */
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        return self.cachedCellLayoutAttributes[indexPath]
        
    }
    
    // MARK: Layout
    
    /**
     Configures the layout for cell type: Big
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addBigCellLayout(atIndexPath indexPath:IndexPath, atRow row:Int) {
        let cellWidth = layoutAttributes(withCellType: .big, indexPath: indexPath, atRow: row)
        
        rows[row].appendToRow(withWidth: cellWidth)
        rows[row + 1].appendToRow(withWidth: cellWidth)
    }
    
    /**
     Configures the layout for cell type: Small
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addSmallCellLayout(atIndexPath indexPath:IndexPath, atRow row:Int) {
        let cellWidth = layoutAttributes(withCellType: .small, indexPath: indexPath, atRow: row)
        
        rows[row].appendToRow(withWidth: cellWidth)
    }
    
    /**
     Creates layout attribute with the given parameter and adds it to cache
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: new cell height from layout
     */
    func layoutAttributes(withCellType type:TRMosaicCellType, indexPath:IndexPath, atRow row:Int) -> CGFloat {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = mosaicCellRect(withType: type, atIndexPath: indexPath, atRow: row)
        
        layoutAttributes.frame = frame
        
        let cellWidth = layoutAttributes.frame.size.width + insetForMosaicCell().left
        
        cachedCellLayoutAttributes[indexPath] = layoutAttributes
        
        return cellWidth
    }
    
    // MARK: Cell Sizing
    
    /**
     Creates the bounding rectangle for the given cell type
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: Bounding rectangle
     */
    func mosaicCellRect(withType type: TRMosaicCellType, atIndexPath indexPath:IndexPath, atRow row:Int) -> CGRect {
        var cellHeight = cellContentHeightFor(mosaicCellType: type)
        var cellWidth = cellContentWidthFor(mosaicCellType: type)
        
        var originY = CGFloat(row) * (contentHeight / CGFloat(numberOfRowsInSection))
        var originX = rows[row].rowWidth
        
        let sectionInset = insetForMosaicCell()
        
        originX += sectionInset.left
        originY += sectionInset.top
        
        cellWidth -= sectionInset.right
        cellHeight -= sectionInset.bottom
        
        return CGRect(x: originX, y: originY, width: cellWidth, height: cellHeight)
    }
    
    /**
     Calculates height for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated height
     */
    func cellContentWidthFor(mosaicCellType cellType:TRMosaicCellType) -> CGFloat {
        let width = delegate.widthForSmallMosaicCell()
        if cellType == .big {
            return width * 2
        }
        return width
    }
    
    /**
     Calculates width for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated width
     */
    func cellContentHeightFor(mosaicCellType cellType:TRMosaicCellType) -> CGFloat {
        let height = contentHeight
        if cellType == .big {
            return height
        }
        return height / 2
    }
    
    // MARK: Orientation
    
    /**
     Determines if a layout update is needed when the bounds have been changed
     
     - returns: True if layout needs update
     */
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let currentBounds:CGRect = self.collectionView!.bounds
        
        if currentBounds.size.equalTo(newBounds.size) {
            self.prepare()
            return true
        }
        
        return false
    }
    
    // MARK: Delegate Wrappers
    
    /**
     Returns the cell type for the specified cell at index path
     
     - returns: Cell type
     */
    func mosaicCellType(index indexPath:IndexPath) -> TRMosaicCellType {
        return delegate.collectionView(collectionView!, mosaicCellSizeTypeAtIndexPath:indexPath)
    }
    
    /**
     - returns: Returns the UIEdgeInsets that will be used for every cell as a border
     */
    func insetForMosaicCell() -> UIEdgeInsets {
        return delegate.collectionView(collectionView!, layout: self, insetAtSection: 0)
    }
}

extension TRMosaicHorizontalLayout {
    
    // MARK: Helper Functions
    
    /**
     - returns: The index of the column with the smallest height
     */
    func indexOfShortestRow() -> Int {
        var index = 0
        for i in 1..<numberOfRowsInSection {
            if rows[i] < rows[index] {
                index = i
            }
        }
        return index
    }
    
    /**
     Resets the layout cache and the heights array
     */
    func resetLayoutState() {
        rows = TRMosaicRows()
        cachedCellLayoutAttributes = [IndexPath:UICollectionViewLayoutAttributes]()
    }
}
