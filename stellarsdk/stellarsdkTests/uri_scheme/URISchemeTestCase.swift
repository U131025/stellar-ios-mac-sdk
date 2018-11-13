//
//  URISchemeTestCase.swift
//  stellarsdkTests
//
//  Created by Soneso on 11/09/2018.
//  Copyright © 2018 Soneso. All rights reserved.
//

import XCTest
import stellarsdk

class URISchemeTestCase: XCTestCase {
    let sdk = StellarSDK()
    let publicKey = Data(base64Encoded:"uHFsF4DaBlIsPUzFlMuBFkgEROGR9DlEBYCg3x+V72A=")!
    let privateKey = Data(base64Encoded: "KJJ6vrrDOe9XIDAj6iSftUzux0qWwSwf3er27YKUOU2ZbT/G/wqFm/tDeez3REW5YlD5mrf3iidmGjREBzOEjQ==")!
    let unsignedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com"

    let signedURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&signature=ZV%2BegOAcv%2FMTua5vOXA0JkXp3sKq1F4cNg7F0RIQQbThQ9%2FmuEzzU21GEb3qQ%2Fl95CuhLVP6IW8eU1aFob7MAA%3D%3D"

    let validURL = "web+stellar:tx?xdr=AAAAALhxbBeA2gZSLD1MxZTLgRZIBEThkfQ5RAWAoN8fle9gAAAAZAAB0xgAAAACAAAAAAAAAAAAAAABAAAAAQAAAAC4cWwXgNoGUiw9TMWUy4EWSARE4ZH0OUQFgKDfH5XvYAAAAAkAAAAAAAAAAA%3D%3D&origin_domain=place.domain.com&signature=ca5NoydAhPz10%2BFTGLN4gThguXfB%2FL2xO31wlcNu87ypmM2deNFdyXFWkgxwIirGOvQOtgRZvW%2BkwC%2Bucu4MBA%3D%3D"
    
    let uriValidator = URISchemeValidator()
    
    var tomlResponseMock: TomlResponseMock!
    var tomlResponseSignatureMismatchMock: TomlResponseSignatureMismatchMock!
    var tomlResponseSignatureMissingMock: TomlResponseSignatureMissingMock!
    
    override func setUp() {
        super.setUp()
        
        URLProtocol.registerClass(ServerMock.self)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tomlResponseMock = nil
        tomlResponseSignatureMismatchMock = nil
        tomlResponseSignatureMissingMock = nil
        super.tearDown()
    }
    
    func testGetTransactionOperationURIScheme() {
        let expectation = XCTestExpectation(description: "URL Returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        sdk.accounts.getAccountDetails(accountId: keyPair.accountId) { (response) -> (Void) in
            switch response {
            case .success(let data):
                let operationBody = OperationBodyXDR.inflation
                let operation = OperationXDR(sourceAccount: keyPair.publicKey, body: operationBody)
                let transaction = TransactionXDR(sourceAccount: keyPair.publicKey, seqNum: data.sequenceNumber + 1, timeBounds: nil, memo: .none, operations: [operation])
                let uriSchemeBuilder = URIScheme()
                let uriScheme = uriSchemeBuilder.getSignTransactionURI(transactionXDR: transaction)
                print("URIScheme: \(uriScheme)")
                XCTAssert(true)
                expectation.fulfill()
            case .failure(let error):
                StellarSDKLog.printHorizonRequestErrorMessage(tag:"TS Test", horizonRequestError:error)
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testGetPaymentOperationURIScheme() {
        let expectation = XCTestExpectation(description: "URL Returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let uriSchemeBuilder = URIScheme()
        let uriScheme = uriSchemeBuilder.getPayOperationURI(accountID: keyPair.accountId)
        print("PayOperationURI: \(uriScheme)")
        expectation.fulfill()
    }
    
    func testMissingSignatureFromURIScheme() {
        let expectation = XCTestExpectation(description: "Missing signature failure.")
        tomlResponseMock = TomlResponseMock(address: "place.domain.com")
        uriValidator.checkURISchemeIsValid(url: unsignedURL) { (response) -> (Void) in
            switch response {
            case .failure(let error):
                if error == URISchemeErrors.missingSignature {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testMissingDomainFromURIScheme() {
        let expectation = XCTestExpectation(description: "Missing origin domain failure.")
        
        uriValidator.checkURISchemeIsValid(url: signedURL) { (response) -> (Void) in
            switch response {
            case .failure(let error):
                if error == URISchemeErrors.missingOriginDomain{
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }

            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testSigningURI() {
        let expectation = XCTestExpectation(description: "Signed URL returned.")
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let result = uriValidator.signURI(url: unsignedURL, signerKeyPair: keyPair)
        switch result {
            case .success(signedURL: let signedURL):
                print("Singing complete: \(signedURL)")
                XCTAssert(true)
            case .failure:
                XCTAssert(false)
        }
        
        expectation.fulfill()
    }
    
    func testValidURIScheme() {
        let expectation = XCTestExpectation(description: "URL is valid.")
        tomlResponseMock = TomlResponseMock(address: "place.domain.com")
        uriValidator.checkURISchemeIsValid(url: validURL) { (response) -> (Void) in
            switch response {
                case .success():
                    XCTAssert(true)
                case .failure(let error):
                    print("ValidURIScheme Error: \(error)")
                    XCTAssert(false)
            }

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTransactionSigning() {
        let expectation = XCTestExpectation(description: "The transaction is signed and sent to the stellar network")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .success:
                XCTAssert(true)
            case .failure(error: let error):
                XCTAssert(false)
                print("Transaction signing failed! Error: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testSourceAccountAndSignerAccountMismatch() {
        let expectation = XCTestExpectation(description: "The transaction's source account is different than the sginer's public key")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(secretSeed: "SC4CGETADVYTCR5HEAVZRB3DZQY5Y4J7RFNJTRA6ESMHIPEZUSTE2QDK")
        
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction signing failed! Error: |\(error)|")
               
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "Transaction\'s source account is no match for signer\'s public key!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testTransactionXDRMissing() {
        let expectation = XCTestExpectation(description: "The transaction is missing from the url!")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        let url = "web+stellar:tx?xdr=asdasdsadsadsa"
        uriBuilder.signTransaction(forURL: url, signerKeyPair: keyPair) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction missing from url! Error: \(error)")
                
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "TransactionXDR missing from url!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func testConfirmationTransaction() {
        let expectation = XCTestExpectation(description: "The transaction is going to be canceled by not confirming it!")
        let uriBuilder = URIScheme()
        let keyPair = try! KeyPair(publicKey: PublicKey([UInt8](publicKey)), privateKey: PrivateKey([UInt8](privateKey)))
        uriBuilder.signTransaction(forURL: validURL, signerKeyPair: keyPair, transactionConfirmation: { (transaction) -> (Bool) in
            return false
        }) { (response) -> (Void) in
            switch response {
            case .failure(error: let error):
                print("Transaction was not confirmed! Error: \(error)")
            
                switch error {
                case .requestFailed(let message):
                    XCTAssertEqual("\(message)", "Transaction was not confirmed!")
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15)
    }
    
    
    func testTomlSignatureMismatch() {
        tomlResponseSignatureMismatchMock = TomlResponseSignatureMismatchMock(address: "place.domain.com")
        let expectation = XCTestExpectation(description: "The signature from the toml file is a mismatch with the one cached!")
        
        uriValidator.checkURISchemeIsValid(url: validURL, warningClosure: {
            XCTAssert(true)
            expectation.fulfill()
        }) { (response) -> (Void) in
            switch response {
            case .success():
                XCTAssert(true)
            case .failure(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testTomlSignatureMissing() {
        let expectation = XCTestExpectation(description: "The signature field is missing from the toml file!")
        tomlResponseSignatureMissingMock = TomlResponseSignatureMissingMock(address: "place.domain.com")
        
        uriValidator.checkURISchemeIsValid(url: validURL) { (response) -> (Void) in
            switch response {
            case .success():
                XCTAssert(false)
            case .failure(let error):
                print("ValidURIScheme Error: \(error)")
                if error == URISchemeErrors.tomlSignatureMissing {
                    XCTAssert(true)
                } else {
                    XCTAssert(false)
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)

    }
}

