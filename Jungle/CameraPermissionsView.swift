//
//  CameraPermissionsView.swift
//  Jungle
//
//  Created by Robert Canton on 2017-08-10.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit

protocol CameraPermissionsProtocol:class {
    func dismissPermissionsView()
    func resendTapped()
    func enableLocationTapped()
    func allowCameraTapped()
    func allowMicrophoneTapped()
}

class CameraPermissionsView: UIView {
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var enableLocationButton: UIButton!
    @IBOutlet weak var allowCameraButton: UIButton!
    @IBOutlet weak var allowMicrophoneButton: UIButton!

    @IBOutlet weak var verifyView: UIView!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var microphoneView: UIView!

    @IBOutlet weak var verifyLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var container: UIView!
    
    weak var delegate:CameraPermissionsProtocol?
    override func awakeFromNib() {
        super.awakeFromNib()
        
        container.layer.cornerRadius = 12.0
        container.clipsToBounds = true
        
        resendButton.layer.cornerRadius = resendButton.frame.height / 2
        resendButton.clipsToBounds = true
        resendButton.setGradient(colorA: lightAccentColor, colorB: accentColor)
        enableLocationButton.layer.cornerRadius = enableLocationButton.frame.height / 2
        enableLocationButton.clipsToBounds = true
        enableLocationButton.setGradient(colorA: lightAccentColor, colorB: accentColor)
        allowCameraButton.layer.cornerRadius = allowCameraButton.frame.height / 2
        allowCameraButton.clipsToBounds = true
        allowCameraButton.setGradient(colorA: lightAccentColor, colorB: accentColor)
        allowMicrophoneButton.layer.cornerRadius = allowMicrophoneButton.frame.height / 2
        allowMicrophoneButton.clipsToBounds = true
        allowMicrophoneButton.setGradient(colorA: lightAccentColor, colorB: accentColor)
        
        backView.isUserInteractionEnabled = true
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backViewTapped))
        backView.addGestureRecognizer(tap)
        
    }
    
    
    
    func backViewTapped() {
        delegate?.dismissPermissionsView()
    }
    
    
    func setup(verified:Bool, locationEnabled:Bool, cameraAllowed:Bool, microphoneAllowed:Bool) {
        
        if verified {
            stackView.remove(view: verifyView)
        }
        
        if locationEnabled {
            stackView.remove(view: locationView)
        }
        
        if cameraAllowed {
            stackView.remove(view: cameraView)
        }
        
        if microphoneAllowed {
            stackView.remove(view: microphoneView)
        }
        
    }
    
    var refreshMode = true
    
    func setToResendMode() {
        verifyLabel.text = "Hmm... You are still not verified. Try reopening Jungle or we can send you another verification email."
        resendButton.backgroundColor = infoColor
        resendButton.setTitle("Resend Email", for: .normal)
        refreshMode = false
    }
    
    func setToRefreshMode() {
        verifyLabel.text = "We've sent you an email to verify your account. Tap Refresh once you have been verified."
        resendButton.backgroundColor = accentColor
        resendButton.setTitle("Refresh Account", for: .normal)
        refreshMode = true
    }
    
    @IBAction func resendTapped(_ sender: Any) {
        delegate?.resendTapped()
    }
    
    @IBAction func enableLocationTapped(_ sender: Any) {
        delegate?.enableLocationTapped()
    }
    
    
    @IBAction func allowCameraTapped(_ sender: Any) {
        delegate?.allowCameraTapped()
    }
    
    
    @IBAction func allowMicrophoneTapped(_ sender: Any) {
        delegate?.allowMicrophoneTapped()
    }
    
    func removeVerifyView() {
        if stackView.arrangedSubviews.count == 2 { return }
        stackView.remove(view: verifyView)
        
    }
    
    func removeLocationView() {
        if stackView.arrangedSubviews.count == 2 { return }
        stackView.remove(view: locationView)
    }
    
    func removeCameraView() {
        if stackView.arrangedSubviews.count == 2 { return }
        stackView.remove(view: cameraView)
    }
    
    
    func removeMicrophoneView() {
        if stackView.arrangedSubviews.count == 2 { return }
        stackView.remove(view: microphoneView)
    }
    

}
