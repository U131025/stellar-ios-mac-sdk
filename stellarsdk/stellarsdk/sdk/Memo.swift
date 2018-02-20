//
//  Memo.swift
//  stellarsdk
//
//  Created by Istvan Elekes on 2/16/18.
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public enum Memo {
    case none
    case text (String)
    case id (UInt64)
    case hash (Data)
    case returnHash (Data)
}

extension Memo: MemoProtocol {
    func toXDR() -> MemoXDR {
        switch self {
            case .none: return MemoXDR.none
            case .text(let text): return MemoXDR.text(text)
            case .id(let id): return MemoXDR.id(id)
            case .hash(let hash): return MemoXDR.hash(WrappedData32(hash))
            case .returnHash(let hash): return MemoXDR.returnHash(WrappedData32(hash))
        }
    }
    
    init?(text:String) throws {
        if text.utf8CString.count > 28 {
            throw StellarSDKError.invalidArgument(message: "text must be <= 28 bytes. length=\(text.count)" )
        }
        self = .text(text)
    }
    
    init?(hash:Data) throws {
        if (hash.count > 32) {
            throw StellarSDKError.invalidArgument(message: "MEMO_HASH can contain 32 bytes at max.")
        }
        self = .hash(hash)
    }
    
    init?(returnHash:Data) throws {
        if (returnHash.count > 32) {
            throw StellarSDKError.invalidArgument(message: "MEMO_RETURN_HASH can contain 32 bytes at max.")
        }
        self = .returnHash(returnHash)
    }
}

extension Memo:MemoHashProtocol {
    
    func hexValue() throws -> String {
        switch self {
        case .hash(let hash):
            return hash.hexEncodedString()
        case .returnHash(let returnHash):
            return returnHash.hexEncodedString()
        default:
            throw StellarSDKError.invalidArgument(message: "Only hash, return_hash has hex value")
        }
    }
    
    func trimmedHexValue() throws -> String {
        let str = try self.hexValue().split(separator: "0").first
        return String(describing: str)
    }
}

