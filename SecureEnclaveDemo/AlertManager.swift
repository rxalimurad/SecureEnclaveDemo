//
//  AlertManager.swift
//  SecureEnclaveDemo
//
//  Created by Ali Murad on 11/05/2024.
//

import UIKit
class AlertManager {
    static let shared = AlertManager()
    private init() {}
    func showAlert(title: String, message: String, viewController: UIViewController) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
}

