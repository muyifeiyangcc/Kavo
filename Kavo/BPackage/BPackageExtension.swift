//
//  BPackageExtension.swift
//

import Foundation


// MARK: - 字符串混淆标记

public func MARKER(_ str: String) -> String {
    return str
}



// MARK: - String AES Decrypt

public extension String {


    func BPackagedddDecrypt() -> String {


        let key = "vixiavixiavixiax"
        let iv = ""



        guard let result =
                BPackageTools.BPackageAesDecrypt(
                    text: self,
                    key: key,
                    iv: iv
                )
        else {
            return self
        }



        return result.BPackageTransEscapeCharacter(
            isForward: false
        )
    }



    // MARK: 转义字符处理


    func BPackageTransEscapeCharacter(
        isForward: Bool
    ) -> String {

        let map : KeyValuePairs<String, String> = [
            "\\" : "\\\\",
            "\"" : "\\\"",
            "\'" : "\\\'",
            "\n" : "\\n",
            "\r" : "\\r",
            "\u{000C}" : "\\f",
            "\u{2028}" : "\\u2028",
            "\u{2029}" : "\\u2029"
        ]
        var sendJson = self
        for (k, v) in map {
            let originalStr = isForward ? k : v
            let replacingStr = isForward ? v : k
            sendJson = sendJson.replacingOccurrences(of: originalStr , with: replacingStr)
        }
        return sendJson
    }

}
