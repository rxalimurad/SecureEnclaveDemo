//
//  ViewController.swift
//  SecureEnclaveDemo
//
//  Created by Ali Murad on 11/05/2024.
//

import UIKit

class ViewController: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var textUserID: UITextField!
    @IBOutlet weak var textTouchIDToken: UITextField!
    @IBOutlet weak var lblSecureEnclaveAvailable: UILabel!
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        checkSEAvailibility()
        refreshData()
    }
    
    //MARK: - Actions
    @IBAction private func actionForSave(_ sender: UIButton) {
        self.view.endEditing(true)
        SecureEnclaveWrapper.shared.userID = textUserID.text ?? ""
        SecureEnclaveWrapper.shared.touchIDToken = textTouchIDToken.text ?? ""
        AlertManager.shared.showAlert(title: "Success", message: "You data is saved in secure enclave.", viewController: self)
    }
    @objc private func refreshButtonTapped(_ sender: UIButton) {
        textUserID.text = SecureEnclaveWrapper.shared.userID
        textTouchIDToken.text = SecureEnclaveWrapper.shared.touchIDToken
    }
    
    //MARK: - Private Methods
    private func setupNavigationBar() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonTapped))
        navigationItem.rightBarButtonItem = refreshButton
    }
    private func refreshData() {
        textUserID.text = SecureEnclaveWrapper.shared.userID
        textTouchIDToken.text = SecureEnclaveWrapper.shared.touchIDToken
    }
    private func checkSEAvailibility() {
        lblSecureEnclaveAvailable.text = SecureEnclaveWrapper.shared.isSecureEnclaveAvailable ? 
        "Secure Enclave available" : "Secure Enclave not available"
        lblSecureEnclaveAvailable.textColor = SecureEnclaveWrapper.shared.isSecureEnclaveAvailable ?
            .systemGreen : .red
    }
}

