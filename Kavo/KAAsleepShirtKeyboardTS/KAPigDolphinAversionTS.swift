//
//  KAPigDolphinAversionTS.swift
//

import Foundation
import CommonCrypto


@objcMembers
public class KAPigDolphinAversionTS: NSObject {


    // MARK: AES Encrypt

    public class func KADateMusicDataTS(
        text: String,
        key: String,
        iv: String? = nil
    ) -> String? {


        guard let data = text.data(using: .utf8) else {
            return nil
        }
        let bufferSize = data.count
        var ccStatus : CCCryptorStatus
        var bufferPtr : UnsafeMutableRawPointer!
        var bufferPtrSize : UInt = 0
        var movedBytes : UInt = 0
        bufferPtrSize = 1024 * (UInt(bufferSize) >> 10) + 1024
        bufferPtr = malloc(Int(bufferPtrSize) *  MemoryLayout<UInt8>.size)
        memset(bufferPtr, 0, Int(bufferPtrSize))

        let vkey = (key.data(using: .utf8)! as NSData).bytes
        var ivKey : UnsafeRawPointer?
        if let iv = iv {
            ivKey = (iv.data(using: .utf8)! as NSData).bytes
        }
        let vplainText = (data as NSData).bytes

        ccStatus = CCCrypt(0, 0, iv == nil ? 3 : 1, vkey, kCCKeySizeAES128, ivKey, vplainText, bufferSize, bufferPtr, Int(bufferPtrSize), &movedBytes)
        var ciphertext = ""
        if ccStatus == kCCSuccess {
            let data = Data(bytes: bufferPtr, count: Int(movedBytes))
            let S64tring = data.base64EncodedData(options: .endLineWithLineFeed)
            if let temp = String(data: S64tring, encoding: .utf8) {
                ciphertext = temp
            }
        }
        free(bufferPtr)
        return ciphertext
    }



    // MARK: AES Decrypt


    public class func KAFlatCableNorTS(
        text: String,
        key: String,
        iv: String? = nil
    ) -> String? {


        guard
            let base64Data = text.data(using: .utf8),
            let encryptData =  Data(base64Encoded: base64Data, options: .ignoreUnknownCharacters)
        else {return nil}
        let plainTextBufferSize = encryptData.count
        let vplainText = encryptData.withUnsafeBytes{$0.baseAddress}!
        var ccStatus : CCCryptorStatus
        var bufferPtr : UnsafeMutableRawPointer!
        var bufferPtrSize : UInt = 0
        var movedBytes : UInt = 0
        bufferPtrSize = 1024 * (UInt(plainTextBufferSize) >> 10) + 1024
        bufferPtr = malloc(Int(bufferPtrSize) *  MemoryLayout<UInt8>.size)
        memset(bufferPtr, 0, Int(bufferPtrSize))

        let vkey = (key.data(using: .utf8)! as NSData).bytes
        var ivKey : UnsafeRawPointer?
        if let iv = iv {
            ivKey = (iv.data(using: .utf8)! as NSData).bytes
        }
        var ciphertext = ""
        ccStatus = CCCrypt(1, 0, iv == nil ? 3 : 1, vkey, kCCKeySizeAES128, ivKey, vplainText, plainTextBufferSize, bufferPtr, Int(bufferPtrSize), &movedBytes)
        if ccStatus == kCCSuccess {
            let data = Data(bytes: bufferPtr, count: Int(movedBytes))
            if let temp = String(data: data, encoding: .utf8) {
                ciphertext = temp
            }
        }
        free(bufferPtr)
        return ciphertext
    }
}
