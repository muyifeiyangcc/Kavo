//
//  KAOctopusQueVcTS.swift
//

import Foundation


// MARK: - String obfuscation marker

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



    // MARK: Escape character handling


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
