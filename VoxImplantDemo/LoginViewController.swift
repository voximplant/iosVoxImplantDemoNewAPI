//
//  ViewController.swift
//  VoxImplantDemo
//
//  Created by Andrey Syvrachev on 27.01.17.
//  Copyright © 2017 Andrey Syvrachev. All rights reserved.
//

import UIKit
import VoxImplant

class LoginViewController: UIViewController {

    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var gateway: UITextField!
    
    var vx:VIClient?
    
    private func loadUserDefaults(){
        let defaults = UserDefaults.standard
        userName.text = defaults.string(forKey: "user")
        password.text = defaults.string(forKey: "password")
        gateway.text = defaults.string(forKey: "gateway")
    }
    
    private func saveUserDefaults(){
        let defaults = UserDefaults.standard
        defaults.setValue(userName.text, forKey: "user")
        defaults.setValue(password.text, forKey: "password")
        defaults.setValue(gateway.text, forKey: "gateway")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadUserDefaults()

        NotificationCenter.default.addObserver(self, selector: #selector(disconnected), name: Notify.disconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(incomingPush), name: Notify.incomingPush, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notify.disconnected, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notify.incomingPush, object: nil)
    }
    
    
    func disconnected(){
       // Log.debug("disconnected")
        self.setUIDisconnected()
    }
    
    
    func setUIDisconnected(){
        self.loginButton.isEnabled = true
        self.activityIndicator.stopAnimating()
        self.loginButton.setTitle("Login", for: .normal)
    }
    
    func setUIConnecting(){
        self.activityIndicator.startAnimating()
        self.loginButton.setTitle("Cancel", for: .normal)
    }
    
    func isConnecting() -> Bool {
        return self.activityIndicator.isAnimating
    }
    
    func login(){
        self.saveUserDefaults()
        
        self.setUIConnecting()

        voxController.login(user: userName.text!,
                            password: password.text!,
                            gateway: gateway.text,
                            success: { (displayName, authParams) in
            
            let phoneController = self.storyboard?.instantiateViewController(withIdentifier: "PhoneController")
            phoneController!.title = displayName
            self.navigationController?.pushViewController(phoneController!, animated: true)
            
            self.setUIDisconnected()
            
        }) { (error) in
            
            let reason = error?.localizedDescription
            let alert = UIAlertController(title: "Error", message: reason != nil ? "\(String(describing: reason))":"", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .destructive, handler: nil))
            self.present(alert,animated: true, completion: nil)
            
            self.setUIDisconnected()
        }
    }

    @IBAction func loginButtonClicked(_ sender: Any) {
        
        if (!isConnecting()) {
            login()
        }else {
            voxController.disconnect()
            self.loginButton.isEnabled = false
        }

    }
    
    func incomingPush() {

        if (!isConnecting()) {
            login()
        }
    }
}




