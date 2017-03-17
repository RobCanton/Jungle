/// :nodoc:

public enum Color { case r, b }

/**
 A [red-black binary search tree](https://en.wikipedia.org/wiki/Red–black_tree). Adapted
 from Airspeed Velocity's [implementation](http://airspeedvelocity.net/2015/07/22/a-persistent-tree-using-indirect-enums-in-swift/),
 Chris Okasaki's [Purely Functional Data Structures](http://www.cs.cmu.edu/~rwh/theses/okasaki.pdf),
 and Stefan Kahrs' [Red-black trees with types](http://dl.acm.org/citation.cfm?id=968482),
 which is implemented in the [Haskell standard library](https://hackage.haskell.org/package/llrbtree-0.1.1/docs/Data-Set-RBTree.html).
 Elements must be comparable with [Strict total order](https://en.wikipedia.org/wiki/Total_order#Strict_total_order).
 Full documentation is available [here](http://oisdk.github.io/SwiftDataStructures/Enums/Tree.html).
 */

public enum Tree<Element: Comparable> : Equatable {
    case empty
    indirect case node(Color,Tree<Element>,Element,Tree<Element>)
}

/// :nodoc:

public func ==<E : Comparable>(lhs: Tree<E>, rhs: Tree<E>) -> Bool {
    return lhs.elementsEqual(rhs)
}

// MARK: Initializers

extension Tree : ExpressibleByArrayLiteral {
    
    /// Create an empty `Tree`.
    
    public init() { self = .empty }
    
    fileprivate init(
        _ x: Element,
          color: Color = .b,
          left: Tree<Element> = .empty,
          right: Tree<Element> = .empty
        ) {
        self = .node(color, left, x, right)
    }
    
    /// Create a `Tree` from a sequence
    
    public init<S : Sequence>(_ seq: S) where S.Iterator.Element == Element {
        self.init()
        for x in seq { insert(x) }
    }
    
    /// Create a `Tree` of `elements`
    
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Tree: CustomDebugStringConvertible {
    
    /// A description of `self`, suitable for debugging
    
    public var debugDescription: String {
        return Array(self).debugDescription
    }
}

// MARK: Properties

extension Tree {
    /**
     Returns the smallest element in `self` if it's present, or `nil` if `self` is empty
     
     - Complexity: O(*log n*)
     */
    
    public var first: Element? {
        return minElement()
    }
    
    /**
     Returns the largest element in `self` if it's present, or `nil` if `self` is empty
     
     - Complexity: O(*log n*)
     */
    
    public var last: Element? {
        return maxElement()
    }
    
    /// Returns `true` iff `self` is empty
    
    public var isEmpty: Bool {
        return self == .empty
    }
    
    /**
     Returns the number of elements in `self`
     
     - Complexity: O(`count`)
     */
    
    public var count: Int {
        guard case let .node(_, l, _, r) = self else { return 0 }
        return 1 + l.count + r.count
    }
}

// MARK: Balance

/// :nodoc:

internal enum TreeBalance {
    case balanced(blackHeight: Int)
    case unBalanced
}

extension Tree {
    internal var isBalanced: Bool {
        switch balance {
        case .balanced: return true
        case .unBalanced: return false
        }
    }
    
    internal var color: Color {
        if case .node(.r, _, _, _) = self { return .r }
        return .b
    }
    
    internal var balance: TreeBalance {
        guard case let .node(c, l, _, r) = self else { return .balanced(blackHeight: 1) }
        if
            case let .node(_, _, lx, _) = l,
            case let .node(_, _, rx, _) = r, lx >= rx { return .unBalanced }
        guard
            case let .balanced(x) = l.balance,
            case let .balanced(y) = r.balance, x == y else { return .unBalanced }
        if case .b = c { return .balanced(blackHeight: x + 1) }
        guard case .b = l.color, case .b = r.color else { return .unBalanced }
        return .balanced(blackHeight: x)
    }
    
    fileprivate func balL() -> Tree {
        switch self {
        case let .node(.b, .node(.r, .node(.r, a, x, b), y, c), z, d):
            return .node(.r, .node(.b,a,x,b),y,.node(.b,c,z,d))
        case let .node(.b, .node(.r, a, x, .node(.r, b, y, c)), z, d):
            return .node(.r, .node(.b,a,x,b),y,.node(.b,c,z,d))
        default:
            return self
        }
    }
    
    fileprivate func balR() -> Tree {
        switch self {
        case let .node(.b, a, x, .node(.r, .node(.r, b, y, c), z, d)):
            return .node(.r, .node(.b,a,x,b),y,.node(.b,c,z,d))
        case let .node(.b, a, x, .node(.r, b, y, .node(.r, c, z, d))):
            return .node(.r, .node(.b,a,x,b),y,.node(.b,c,z,d))
        default:
            return self
        }
    }
    
    fileprivate func unbalancedR() -> (result: Tree, wasBlack: Bool) {
        guard case let .node(c, l, x, .node(rc, rl, rx, rr)) = self else {
            preconditionFailure(
                "Should not call unbalancedR on an empty Tree or a Tree with an empty right"
            )
        }
        switch rc {
        case .b:
            return (Tree.node(.b, l, x, .node(.r, rl, rx, rr)).balR(), c == .b)
        case .r:
            guard case let .node(_, rll, rlx, rlr) = rl else {
                preconditionFailure("rl empty")
            }
            return (
                Tree.node(.b, Tree.node(.b, l, x, .node(.r, rll, rlx, rlr)).balR(), rx, rr), false
            )
        }
    }
    
    fileprivate func unbalancedL() -> (result: Tree, wasBlack: Bool) {
        guard case let .node(c, .node(lc, ll, lx, lr), x, r) = self else {
            preconditionFailure(
                "Should not call unbalancedL on an empty Tree or a Tree with an empty left"
            )
        }
        switch lc {
        case .b:
            return (Tree.node(.b, .node(.r, ll, lx, lr), x, r).balL(), c == .b)
        case .r:
            guard case let .node(_, lrl, lrx, lrr) = lr else {
                preconditionFailure("lr empty")
            }
            return (
                Tree.node(.b, ll, lx, Tree.node(.b, .node(.r, lrl, lrx, lrr), x, r).balL()), false
            )
        }
    }
}

// MARK: Contains

extension Tree {
    fileprivate func cont(_ x: Element, _ p: Element) -> Bool {
        guard case let .node(_, l, y, r) = self else { return x == p }
        return x < y ? l.cont(x, p) : r.cont(x, y)
    }
    
    /**
     Returns `true` iff `self` contains `x`
     
     - Complexity: O(*log n*)
     */
    
    public func contains(_ x: Element) -> Bool {
        guard case let .node(_, l, y, r) = self else { return false }
        return x < y ? l.contains(x) : r.cont(x, y)
    }
}

// MARK: Insert

extension Tree {
    fileprivate func ins(_ x: Element) -> Tree {
        guard case let .node(c, l, y, r) = self else { return Tree(x, color: .r) }
        if x < y { return Tree(y, color: c, left: l.ins(x), right: r).balL() }
        if y < x { return Tree(y, color: c, left: l, right: r.ins(x)).balR() }
        return self
    }
    
    /**
     Inserts `x` into `self`
     
     - Complexity: O(*log n*)
     */
    
    public mutating func insert(_ x: Element) {
        guard case let .node(_, l, y, r) = ins(x) else {
            preconditionFailure("ins should not return an empty tree")
        }
        self = .node(.b, l, y, r)
    }
}

// MARK: SequenceType

extension Tree : Sequence {
    /**
     Runs a `TreeGenerator` over the elements of `self`. (The elements are presented in
     order, from smallest to largest)
     */
    
    public func makeIterator() -> TreeGenerator<Element> {
        return TreeGenerator(stack: [], curr: self)
    }
}

/**
 A `Generator` for a Tree
 */

public struct TreeGenerator<Element : Comparable> : IteratorProtocol {
    fileprivate var (stack, curr): ([Tree<Element>], Tree<Element>)
    /**
     Advance to the next element and return it, or return `nil` if no next element exists.
     */
    public mutating func next() -> Element? {
        while case let .node(_, l, x, r) = curr {
            if case .empty = l {
                curr = r
                return x
            } else {
                stack.append(curr)
                curr = l
            }
        }
        guard case let .node(_, _, x, r)? = stack.popLast()
            else { return nil }
        curr = r
        return x
    }
}

// MARK: Max, min

extension Tree {
    /**
     Returns the smallest element in `self` if it's present, or `nil` if `self` is empty
     
     - Complexity: O(*log n*)
     */
    
    public func minElement() ->  Element? {
        switch self {
        case .empty: return nil
        case .node(_, .empty, let e, _): return e
        case .node(_, let l, _, _): return l.minElement()
        }
    }
    
    /**
     Returns the largest element in `self` if it's present, or `nil` if `self` is empty
     
     - Complexity: O(*log n*)
     */
    
    public func maxElement() -> Element? {
        switch self {
        case .empty: return nil
        case .node(_, _, let e, .empty) : return e
        case .node(_, _, _, let r): return r.maxElement()
        }
    }
    
    fileprivate func _deleteMin() -> (Tree, Bool, Element) {
        switch self {
        case .empty:
            preconditionFailure("Should not call _deleteMin on an empty Tree")
        case let .node(.b, .empty, x, .empty):
            return (.empty, true, x)
        case let .node(.b, .empty, x, .node(.r, rl, rx, rr)):
            return (.node(.b, rl, rx, rr), false, x)
        case let .node(.r, .empty, x, r):
            return (r, false, x)
        case let .node(c, l, x, r):
            let (l0, d, m) = l._deleteMin()
            guard d else { return (.node(c, l0, x, r), false, m) }
            let tD = Tree.node(c, l0, x, r).unbalancedR()
            return (tD.0, tD.1, m)
        }
    }
    
    /**
     Removes the smallest element from `self` and returns it if it exists, or returns `nil`
     if `self` is empty.
     
     - Complexity: O(*log n*)
     */
    
    public mutating func popFirst() -> Element? {
        guard case .node = self else { return nil }
        let (t, _, x) = _deleteMin()
        self = t
        return x
    }
    
    /**
     Removes the smallest element from `self` and returns it.
     
     - Complexity: O(*log n*)
     - Precondition: `!self.isEmpty`
     */
    
    public mutating func removeFirst() -> Element? {
        guard case .node = self else { return nil }
        let (t, _, x) = _deleteMin()
        self = t
        return x
    }
    
    fileprivate func _deleteMax() -> (Tree, Bool, Element) {
        switch self {
        case .empty:
            preconditionFailure("Should not call _deleteMax on an empty Tree")
        case let .node(.b, .empty, x, .empty):
            return (.empty, true, x)
        case let .node(.b, .node(.r, rl, rx, rr), x, .empty):
            return (.node(.b, rl, rx, rr), false, x)
        case let .node(.r, l, x, .empty):
            return (l, false, x)
        case let .node(c, l, x, r):
            let (r0, d, m) = r._deleteMax()
            guard d else { return (.node(c, l, x, r0), false, m) }
            let tD = Tree.node(c, l, x, r0).unbalancedL()
            return (tD.0, tD.1, m)
        }
    }
    
    
    
    /**
     Removes the largest element from `self` and returns it if it exists, or returns `nil`
     if `self` is empty.
     
     - Complexity: O(*log n*)
     */
    
    public mutating func popLast() -> Element? {
        guard case .node = self else { return nil }
        let (t, _, x) = _deleteMax()
        self = t
        return x
    }
    
    /**
     Removes the largest element from `self` and returns it.
     
     - Complexity: O(*log n*)
     - Precondition: `!self.isEmpty`
     */
    
    public mutating func removeLast() -> Element {
        let (t, _, x) = _deleteMax()
        self = t
        return x
    }
}

// MARK: Delete

extension Tree {
    fileprivate func del(_ x: Element) -> (Tree, Bool)? {
        guard case let .node(c, l, y, r) = self else { return nil }
        if x < y {
            guard let (l0, d) = l.del(x) else { return nil }
            let t = Tree.node(c, l0, y, r)
            return d ? t.unbalancedR() : (t, false)
        } else if y < x {
            guard let (r0, d) = r.del(x) else { return nil }
            let t = Tree.node(c, l, y, r0)
            return d ? t.unbalancedL() : (t, false)
        }
        if case .empty = r {
            guard case .b = c else { return (l, false) }
            if case let .node(.r, ll, lx, lr) = l { return (.node(.b, ll, lx, lr), false) }
            return (l, true)
        }
        let (r0, d, m) = r._deleteMin()
        let t = Tree.node(c, l, m, r0)
        return d ? t.unbalancedL() : (t, false)
    }
    
    /**
     Removes `x` from `self` and returns it if it is present, or `nil` if it is not.
     
     - Complexity: O(*log n*)
     */
    
    public mutating func remove(_ x: Element) -> Element? {
        guard let (t, _) = del(x) else { return nil }
        if case let .node(_, l, y, r) = t {
            self = .node(.b, l, y, r)
        } else {
            self = .empty
        }
        return x
    }
}

// MARK: Reverse

extension Tree {
    /**
     Returns a sequence of the elements of `self` from largest to smallest
     */
    
    public func reverse() -> ReverseTreeGenerator<Element> {
        return ReverseTreeGenerator(stack: [], curr: self)
    }
}

/**
 A `Generator` for a Tree, that iterates over it in reverse.
 */

public struct ReverseTreeGenerator<Element : Comparable> : IteratorProtocol, Sequence {
    fileprivate var (stack, curr): ([Tree<Element>], Tree<Element>)
    /// :nodoc:
    public mutating func next() -> Element? {
        while case let .node(_, l, x, r) = curr {
            if case .empty = r {
                curr = l
                return x
            } else {
                stack.append(curr)
                curr = r
            }
        }
        guard case let .node(_, l, x, _)? = stack.popLast()
            else { return nil }
        curr = l
        return x
    }
}



// MARK: Higher-Order

extension Tree {
    /// :nodoc:
    
    public func reduce<T>(initial: T, combine: (T, Element) throws -> T) rethrows -> T {
        guard case let .node(_, l, x, r) = self else { return initial }
        let lx = try l.reduce(initial, combine)
        let xx = try combine(lx, x)
        let rx = try r.reduce(xx, combine)
        return rx
    }
    
    /// :nodoc:
    
    public func forEach(body: (Element) throws -> ()) rethrows {
        guard case let .node(_, l, x, r) = self else { return }
        try l.forEach(body)
        try body(x)
        try r.forEach(body)
    }
}
