//
//  KAOctopusQueVcTS.swift
//

import Foundation


// MARK: - 字符串混淆标记

public func MARKER(_ str: String) -> String {
    return str
}



// MARK: - String AES Decrypt

public extension String {


    func KAScouringSkySauceTS() -> String {


        let key = "kavokavokavokavo"
        let iv = ""



        guard let result =
                KAPigDolphinAversionTS.KAFlatCableNorTS(
                    text: self,
                    key: key,
                    iv: iv
                )
        else {
            return self
        }



        return result.KADemonstrateBorderSnowTS(
            isForward: false
        )
    }



    // MARK: 转义字符处理


    func KADemonstrateBorderSnowTS(
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
