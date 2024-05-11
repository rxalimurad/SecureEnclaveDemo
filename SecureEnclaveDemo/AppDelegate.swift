//
//  AppDelegate.swift
//  SecureEnclaveDemo
//
//  Created by Ali Murad on 11/05/2024.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SecureEnclaveWrapper.shared.isSecureEnclaveAvailable
        
        
        return true
    }

}

