import UIKit

public class CodeInputView: UIView, UIKeyInput {
    weak public var delegate: CodeInputViewDelegate?
    private var nextTag = 1
    
    private let numDigits = 6

    // MARK: - UIView
    
    public override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    public override var canResignFirstResponder: Bool
    {
        get {
            return true
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        let digitWidth = frame.width / CGFloat(numDigits)
        // Add four digitLabels
        var frame = CGRect(x: 0, y: 0, width: digitWidth, height: frame.height)
        for index in 1...numDigits {
            let digitLabel = UILabel(frame: frame)
            digitLabel.font = UIFont.systemFont(ofSize: 42)
            digitLabel.tag = index
            digitLabel.text = "–"
            digitLabel.textAlignment = .center
            addSubview(digitLabel)
            frame.origin.x += digitWidth
        }
    }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") } // NSCoding

    
    
    // MARK: - UIKeyInput

    public var hasText: Bool {
        get {
            return nextTag > 1 ? true : false
        }
    }
    
    public func insertText(_ text: String) {
        if nextTag < numDigits + 1 {
            (viewWithTag(nextTag)! as! UILabel).text = text
            nextTag += 1
        }
        
        didChangeCode()
    }

    public func deleteBackward() {
        if nextTag > 1 {
            nextTag -= 1
            (viewWithTag(nextTag)! as! UILabel).text = "–"
        }
        didChangeCode()
   }
    
    func didChangeCode() {
        var code = ""
        for index in 1..<nextTag {
            code += (viewWithTag(index)! as! UILabel).text!
        }
        delegate?.codeInputView(didChangeWithCode: code)
    }

    public func clear() {
        while nextTag > 1 {
            deleteBackward()
        }
    }

    // MARK: - UITextInputTraits

    public var keyboardType: UIKeyboardType { get { return .numberPad } set { } }
}

public protocol CodeInputViewDelegate: class {
    func codeInputView(didChangeWithCode code:String)
}


