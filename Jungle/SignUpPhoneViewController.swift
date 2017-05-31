//
//  SignUpPhoneViewController.swift
//  Jungle
//
//  Created by Robert Canton on 2017-05-29.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CoreTelephony

class SignUpPhoneViewController: UIViewController, UITextFieldDelegate, CountrySelectionProtocol {
    
    weak var newUser:NewUser?
    
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var phoneBorder: UIView!
    
    @IBOutlet weak var countryPrefix: UIButton!
    @IBOutlet weak var switchButton: UIButton!
    var closeButton:UIButton!
    var submitButton:UIButton!
    
    fileprivate var number:String?
    
    var country:Country?
    var prefix:String?
    
    deinit {
        print("Deinit >> SignUpPhoneViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneField.delegate = self
        
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
        
        phoneField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        phoneField.enablesReturnKeyAutomatically = true
        
        setLoginButton(enabled: false)
        
        let networkInfo = CTTelephonyNetworkInfo()
        
        if let carrier = networkInfo.subscriberCellularProvider {
            if let ISOCountryCode = carrier.isoCountryCode?.uppercased() {
                
                let callingCode = getCountryCallingCode(countryRegionCode: ISOCountryCode)
                prefix = "+\(callingCode)"
                countryPrefix.setTitle("\(ISOCountryCode) \(prefix!)", for: .normal)
            }
        }
    }
    
    func didSelectCountry(_ country: Country) {
        countryPrefix.setTitle("\(country.code) \(country.phoneCode)", for: .normal)
        self.prefix = country.phoneCode
    }
    
    func textFieldChanged(_ target:UITextField) {
        switch target {
        case phoneField:
            break
        default:
            break
        }
        number = nil
        setLoginButton(enabled: false)
        
        if let number = phoneField.text, number != "", isValidPhoneNumber(number){
            self.number = number
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
        guard let prefix = self.prefix else { return }
        guard let number = self.number else { return }
        
        PhoneAuthProvider.provider().verifyPhoneNumber("\(prefix)\(number)", completion:{ verificationID, error in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
            } else if verificationID != nil {
                print("Verification ID: \(verificationID!)")
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                self.performSegue(withIdentifier: "toPhoneCode", sender: self)
            }
        })
        //PhoneAuthProvider.provider().
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        phoneField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillAppear), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        phoneField.resignFirstResponder()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case phoneField:
            phoneField.resignFirstResponder()
            handleSubmit()
            break
        default:
            break
        }
        
        return true
    }
    
    let ACCEPTABLE_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_."
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let cs = CharacterSet(charactersIn: ACCEPTABLE_CHARACTERS).inverted
        let filtered: String = (string.components(separatedBy: cs) as NSArray).componentsJoined(by: "")
        return (string == filtered)
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
    
    func getCountryCallingCode(countryRegionCode:String)->String{
        
        let prefixCodes = ["AF": "93", "AE": "971", "AL": "355", "AN": "599", "AS":"1", "AD": "376", "AO": "244", "AI": "1", "AG":"1", "AR": "54","AM": "374", "AW": "297", "AU":"61", "AT": "43","AZ": "994", "BS": "1", "BH":"973", "BF": "226","BI": "257", "BD": "880", "BB": "1", "BY": "375", "BE":"32","BZ": "501", "BJ": "229", "BM": "1", "BT":"975", "BA": "387", "BW": "267", "BR": "55", "BG": "359", "BO": "591", "BL": "590", "BN": "673", "CC": "61", "CD":"243","CI": "225", "KH":"855", "CM": "237", "CA": "1", "CV": "238", "KY":"345", "CF":"236", "CH": "41", "CL": "56", "CN":"86","CX": "61", "CO": "57", "KM": "269", "CG":"242", "CK": "682", "CR": "506", "CU":"53", "CY":"537","CZ": "420", "DE": "49", "DK": "45", "DJ":"253", "DM": "1", "DO": "1", "DZ": "213", "EC": "593", "EG":"20", "ER": "291", "EE":"372","ES": "34", "ET": "251", "FM": "691", "FK": "500", "FO": "298", "FJ": "679", "FI":"358", "FR": "33", "GB":"44", "GF": "594", "GA":"241", "GS": "500", "GM":"220", "GE":"995","GH":"233", "GI": "350", "GQ": "240", "GR": "30", "GG": "44", "GL": "299", "GD":"1", "GP": "590", "GU": "1", "GT": "502", "GN":"224","GW": "245", "GY": "595", "HT": "509", "HR": "385", "HN":"504", "HU": "36", "HK": "852", "IR": "98", "IM": "44", "IL": "972", "IO":"246", "IS": "354", "IN": "91", "ID":"62", "IQ":"964", "IE": "353","IT":"39", "JM":"1", "JP": "81", "JO": "962", "JE":"44", "KP": "850", "KR": "82","KZ":"77", "KE": "254", "KI": "686", "KW": "965", "KG":"996","KN":"1", "LC": "1", "LV": "371", "LB": "961", "LK":"94", "LS": "266", "LR":"231", "LI": "423", "LT": "370", "LU": "352", "LA": "856", "LY":"218", "MO": "853", "MK": "389", "MG":"261", "MW": "265", "MY": "60","MV": "960", "ML":"223", "MT": "356", "MH": "692", "MQ": "596", "MR":"222", "MU": "230", "MX": "52","MC": "377", "MN": "976", "ME": "382", "MP": "1", "MS": "1", "MA":"212", "MM": "95", "MF": "590", "MD":"373", "MZ": "258", "NA":"264", "NR":"674", "NP":"977", "NL": "31","NC": "687", "NZ":"64", "NI": "505", "NE": "227", "NG": "234", "NU":"683", "NF": "672", "NO": "47","OM": "968", "PK": "92", "PM": "508", "PW": "680", "PF": "689", "PA": "507", "PG":"675", "PY": "595", "PE": "51", "PH": "63", "PL":"48", "PN": "872","PT": "351", "PR": "1","PS": "970", "QA": "974", "RO":"40", "RE":"262", "RS": "381", "RU": "7", "RW": "250", "SM": "378", "SA":"966", "SN": "221", "SC": "248", "SL":"232","SG": "65", "SK": "421", "SI": "386", "SB":"677", "SH": "290", "SD": "249", "SR": "597","SZ": "268", "SE":"46", "SV": "503", "ST": "239","SO": "252", "SJ": "47", "SY":"963", "TW": "886", "TZ": "255", "TL": "670", "TD": "235", "TJ": "992", "TH": "66", "TG":"228", "TK": "690", "TO": "676", "TT": "1", "TN":"216","TR": "90", "TM": "993", "TC": "1", "TV":"688", "UG": "256", "UA": "380", "US": "1", "UY": "598","UZ": "998", "VA":"379", "VE":"58", "VN": "84", "VG": "1", "VI": "1","VC":"1", "VU":"678", "WS": "685", "WF": "681", "YE": "967", "YT": "262","ZA": "27" , "ZM": "260", "ZW":"263"]
        let countryDialingCode = prefixCodes[countryRegionCode]
        return countryDialingCode!
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCountrySelection" {
            let dest = segue.destination as! SignUpPhoneCountryViewController
            dest.delegate = self
        }
    }
    
    func isValidPhoneNumber(_ number:String) -> Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: number, options: [], range: NSMakeRange(0, number.characters.count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == number.characters.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }
}
