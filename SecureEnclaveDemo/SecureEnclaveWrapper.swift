//
//  SecureEnclaveWrapper.swift
//  SecureEnclaveDemo
//
//  Created by Ali Murad on 11/05/2024.
//

import Foundation
import Security
import CryptoKit

class SecureEnclaveWrapper {
    private var attrLabelPublic = "com.secenclave.public"
    private var attrLabelPrivate = "com.secenclave.private"
    private var publicKeyRef: SecKey?
    private var privateKeyRef: SecKey?
    static let shared = SecureEnclaveWrapper()
    private init() {
        if lookupPublicKeyRef() == nil || lookupPrivateKeyRef() == nil {
            generateKeyValuePair()
        } else {
            publicKeyRef = lookupPublicKeyRef()
            privateKeyRef = lookupPrivateKeyRef()
        }
    }
    var isSecureEnclaveAvailable: Bool {
        if #available(iOS 13.0, *) {
            return SecureEnclave.isAvailable
        } else {
            return false
        }
    }
    
    var userID: String {
        set {
            if isSecureEnclaveAvailable {
                guard let data = newValue.data(using: .utf8) else { return }
                guard let encryptedNewValue = encryptData(data: data)  else { return }
                KeychainWrapper.standard.set(encryptedNewValue, forKey: "userID")
            } else {
                KeychainWrapper.standard.set(newValue, forKey: "userID")
            }
        }
        get {
            if isSecureEnclaveAvailable {
                guard let encryptedData = KeychainWrapper.standard.data(forKey: "userID") else { return "" }
                guard let decryptedData = decryptData(data: encryptedData) else { return "" }
                return String(data: decryptedData, encoding: .utf8) ?? ""
            } else {
                return KeychainWrapper.standard.string(forKey: "userID") ?? ""
            }
            
        }
    }
    var touchIDToken: String {
        set {
            KeychainWrapper.standard.set(newValue, forKey: "touchIDToken")
        }
        get {
            KeychainWrapper.standard.string(forKey: "touchIDToken") ?? ""
        }
    }
    
    
    //MARK: - Important Private methods
    private func encryptData(data: Data) -> Data? {
        guard let publicKeyRef = publicKeyRef else { return nil }
        var error: Unmanaged<CFError>?
        guard let cipher = SecKeyCreateEncryptedData(publicKeyRef, .eciesEncryptionCofactorX963SHA256AESGCM, data as CFData, &error) else { return nil }
        return cipher as Data
    }
    
    private func decryptData(data: Data) -> Data? {
        guard let privateKeyRef = privateKeyRef else { return nil }
        var error: Unmanaged<CFError>?
        guard let plainData = SecKeyCreateDecryptedData(privateKeyRef, .eciesEncryptionCofactorX963SHA256AESGCM, data as CFData, &error) else { return nil }
        return plainData as Data
    }
    
    //MARK: - Helper Private methods
    private func generateKeyValuePair() {
        let accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, .privateKeyUsage, nil)
        guard let accessControl = accessControl else { return }
        let privateKeyParams: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: attrLabelPrivate,
            kSecAttrAccessControl as String: accessControl
        ]
        
        let publicKeyParams: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: attrLabelPublic,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256
        ]
        
        let keyPairParams: [String: Any] = [
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecPrivateKeyAttrs as String: privateKeyParams,
            kSecPublicKeyAttrs as String: publicKeyParams
        ]
        var publicKey, privateKey: SecKey?
        let status = SecKeyGeneratePair(keyPairParams as CFDictionary, &publicKey, &privateKey)
        
        if status == errSecSuccess {
            if let privateKey, let publicKey {
                savePrivateKeyFromRef(privateKeyRef: privateKey)
                savePublicKeyFromRef(publicKeyRef: publicKey)
                publicKeyRef = publicKey
                privateKeyRef = privateKey
            }
        } else {
            print("Error generating key pair: \(status)")
        }
    }
    
    private func savePublicKeyFromRef(publicKeyRef: SecKey) {
        let keyClass = kSecAttrKeyClassPublic as String
        
        let queryDictDelete: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPublic
        ]
        
        // Delete existing public key with the same application tag
        let deleteStatus = SecItemDelete(queryDictDelete as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            print("Error deleting old public key: \(deleteStatus)")
            return
        }
        
        let queryDict: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPublic,
            kSecAttrKeyClass as String: keyClass,
            kSecValueData as String: SecKeyCopyExternalRepresentation(publicKeyRef, nil)!,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrEffectiveKeySize as String: 256,
            kSecAttrCanDerive as String: false,
            kSecAttrCanEncrypt as String: true,
            kSecAttrCanDecrypt as String: false,
            kSecAttrCanVerify as String: true,
            kSecAttrCanSign as String: false,
            kSecAttrCanWrap as String: true,
            kSecAttrCanUnwrap as String: false
        ]
        
        let status = SecItemAdd(queryDict as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving public key: \(status)")
        }
    }

    
    private func savePrivateKeyFromRef(privateKeyRef: SecKey) {
        
        let keyClass = kSecAttrKeyClassPrivate as String
        var error: Unmanaged<CFError>?

//        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKeyRef, &error) as Data? else {
//            print("Error: \(error.debugDescription)")
//            return
//        }
        
        let queryDict: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPrivate,
            kSecAttrKeyClass as String: keyClass,
            kSecValueRef as String: privateKeyRef,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrEffectiveKeySize as String: 256,
            kSecAttrCanDerive as String: false,
            kSecAttrCanEncrypt as String: true,
            kSecAttrCanDecrypt as String: false,
            kSecAttrCanVerify as String: true,
            kSecAttrCanSign as String: false,
            kSecAttrCanWrap as String: true,
            kSecAttrCanUnwrap as String: false
        ]
        deletePrivateKey()
        let status = SecItemAdd(queryDict as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving private key: \(status)")
        }
    }


    
    private func lookupPublicKeyRef() -> SecKey? {
        if let publicKeyRef = publicKeyRef {
            return publicKeyRef
        }
        let keyClass = kSecAttrKeyClassPublic as String
        let queryDict: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPublic,
            kSecAttrKeyClass as String: keyClass,
            kSecReturnRef as String: kCFBooleanTrue as Any
        ]
        var keyRef: CFTypeRef?
        let status = SecItemCopyMatching(queryDict as CFDictionary, &keyRef)
        if status != errSecSuccess || keyRef == nil {
            return nil
        }
        return (keyRef as! SecKey)
    }
    
    
    private func lookupPrivateKeyRef() -> SecKey? {
        
        let keyClass = kSecAttrKeyClassPrivate as String
        let queryDict: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPrivate,
            kSecAttrKeyClass as String: keyClass,
            kSecReturnRef as String: kCFBooleanTrue as Any
        ]
        var keyRef: CFTypeRef?
        let status = SecItemCopyMatching(queryDict as CFDictionary, &keyRef)
        if status != errSecSuccess || keyRef == nil {
            return nil
        }
        return (keyRef as! SecKey)
    }
    private func deletePrivateKey() {
        let queryDict: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrApplicationTag as String: attrLabelPrivate,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        let status = SecItemDelete(queryDict as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error deleting private key: \(status)")
        }
    }
    
}
