

//
//  SignUpPasswordViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-28.
//  Copyright © 2017 Robert Canton. All rights reserved.
//



import Foundation
import UIKit
import Firebase

class SignUpPhoneCodeViewController: UIViewController, CodeInputViewDelegate {
    var closeButton:UIButton!
    var submitButton:UIButton!
    
    @IBOutlet weak var inputContainer: UIView!
    
    var code:String?
    var codeInputView:CodeInputView!
    
    deinit {
        print("Deinit >> SignUpPhoneCodeViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        closeButton.setImage(UIImage(named:"navback"), for: .normal)
        closeButton.tintColor = UIColor.black
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        
        submitButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        submitButton.setTitleColor(UIColor.white, for: .normal)
        submitButton.setTitle("Continue", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0, weight: UIFontWeightBold)
        submitButton.center = view.center
        
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        
        view.addSubview(submitButton)
        
        setLoginButton(enabled: false)
        
        codeInputView = CodeInputView(frame: inputContainer.bounds)
        codeInputView.tag = 17
        inputContainer.addSubview(codeInputView)
        codeInputView.delegate = self
        codeInputView.becomeFirstResponder()
        
    }
    
    func codeInputView(didChangeWithCode code: String) {
        self.code = nil
         setLoginButton(enabled: false)
        if code.characters.count == 6 {
            self.code = code
             setLoginButton(enabled: true)
        }
    }
    
    func setLoginButton(enabled:Bool) {
        if enabled {
            submitButton.backgroundColor = accentColor
            submitButton.isEnabled = true
        } else {
            submitButton.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
            submitButton.isEnabled = false
        }
    }
    
    func handleDismiss() {
        self.dismiss(animated: false, completion: nil)
    }
    
    func handleSubmit() {
        guard let code = self.code else { return }
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        
        submitButton.isEnabled = false
        submitButton.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
        submitButton.setTitle("Verifying...", for: .normal)
        
        codeInputView.isUserInteractionEnabled = false
        
        print("\(code) -> \(verificationID)")
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { user, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        submitButton.center = CGPoint(x: view.center.x, y: view.frame.height - keyboardFrame.height - 16.0 - submitButton.frame.height / 2)
        
    }
    
    func keyboardWillDisappear(notification: NSNotification){
    }
    
    override var prefersStatusBarHidden: Bool
        {
        get {
            return true
        }
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
}
