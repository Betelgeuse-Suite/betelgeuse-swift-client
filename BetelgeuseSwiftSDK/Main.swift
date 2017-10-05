//
//  Main.swift
//  BetelgeuseSwiftSDK
//
//  Created by gabriel troia on 10/3/17.
//  Copyright © 2017 Betelgeuse. All rights reserved.
//

import Foundation

public class BetelgeuseSwiftSDK {
    // This will live in Generated Plist
    private static let FILE_NAME = "Data"
    private static let ENDPOINT_URL = "https://rawgit.com/GabrielCTroia/beetlejuice-sample-repo1/master/"
    private static let CURRENT_VERSION = "11.1.1"

    public init() {
        BetelgeuseSwiftSDK.getAllVersions(completionHandler: ({ data in
            print(data.allKeys)
        }))
//        BetelgeuseSwiftSDK.loadUrl()
//
//        if let m = BetelgeuseSwiftSDK.loadDataFromFile() {
//            print("The Model() is \(m.nested.nested.file.value)")
//        }
    }

//    public static func getModel() -> Model? {
//        return BetelgeuseSwiftSDK.loadDataFromFile()
//    }
//
//    private static func loadUrl() {
//        if let url = URL(string: "\(ENDPOINT_URL)/versions.json") {
//            do {
//                let contents = try String(contentsOf: url)
//                print(contents)
//            } catch {
//                // contents could not be loaded
//            }
//        } else {
//            // the URL was bad!
//        }
//    }

    private static func getAllVersions(completionHandler: @escaping(NSDictionary) -> Void) {
        let url = URL(string: "\(ENDPOINT_URL)/versions.json")

        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                print(error)
                return
            }
            do {
                if let jsonResult = try? JSONSerialization.jsonObject(
                    with: data,
                    options: JSONSerialization.ReadingOptions.mutableContainers
                    ) as! NSDictionary {
                    return completionHandler(jsonResult)
                } else {
                    print("Error in reading the json")
                }
            } catch let error as NSError {
                print(error)
            }
        }).resume()
    }

//    private static func loadDataFromFile() -> Model? {
//        let fileName = BetelgeuseSwiftSDK.FILE_NAME
//
//        let podBundle = Bundle(for: BetelgeuseSwiftSDK.self as AnyClass)
//
//        if let bundleURL = podBundle.url(forResource: "BetelgeuseSwiftSDKData", withExtension: "bundle") {
//            if let bundle = Bundle(url: bundleURL) {
//                if let path = bundle.path(forResource: fileName, ofType: "json") {
//                    if let jsonData = try? NSData(
//                        contentsOfFile: path,
//                        options: NSData.ReadingOptions.mappedIfSafe
//                        ) {
//                        if let jsonResult: NSDictionary = try? JSONSerialization.jsonObject(
//                            with: jsonData as Data,
//                            options: JSONSerialization.ReadingOptions.mutableContainers
//                            ) as! NSDictionary {
//
////                            print(jsonResult)
//                            return Model(jsonResult)
//                        }
//                    }
//                }
//            }
//        } else {
//            print("Path \(fileName) not found")
//        }
//
//        return nil
//    }
}
