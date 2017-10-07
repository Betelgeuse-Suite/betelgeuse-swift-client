//
//  Main.swift
//  BetelgeuseSwiftSDK
//
//  Created by gabriel troia on 10/3/17.
//  Copyright © 2017 Betelgeuse. All rights reserved.
//

import Foundation
//import BetelgeuseSampleRepo1

public class Betelgeuse {
    // This will live in Generated Plist
    private let localDataBundlePath: String
    private let remoteDataUrl: URL
    private let versionsRegisterURL: URL
    private let currentVersion: String // Version type

    public init(
        localDataBundlePath: String,

        remoteDataUrl: URL,
        versionsRegisterUrl: URL,
        currentVersion: String) {

        self.localDataBundlePath = localDataBundlePath
        self.remoteDataUrl = remoteDataUrl
        self.versionsRegisterURL = versionsRegisterUrl
        self.currentVersion = currentVersion // todo -> Version Type

        //        this.getAllVersions(completionHandler: ({ data in
        //            print(data.allKeys)
        //        }))
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
    public func getModel<M>() -> M? {
        return self.loadDataFromFile() as? M;
    }

    private func loadDataFromFile() -> NSDictionary? {
        //        let fileName = BetelgeuseSwiftSDK.FILE_NAME

        //        let podBundle = Bundle(for: BetelgeuseSwiftSDK.self as AnyClass)


        //        if let bundleURL = podBundle.url(forResource: "BetelgeuseSwiftSDKData", withExtension: "bundle") {
//        if let bundle = Bundle(url: self.localDataBundleUrl) {
//            if let path = bundle.path(forResource: "Data", ofType: "json") {
                if let jsonData = try? NSData(
                    contentsOfFile: self.localDataBundlePath,
                    options: NSData.ReadingOptions.mappedIfSafe
                    ) {
                    if let jsonResult: NSDictionary = try? JSONSerialization.jsonObject(
                        with: jsonData as Data,
                        options: JSONSerialization.ReadingOptions.mutableContainers
                        ) as! NSDictionary {
                        return jsonResult
                    }
                    else {
                        print("Not a valid json")
                    }
                }
                else {
                    print("Cannot read data from file")
                }
//            }
//            else {
//                print("Path \(path) not found")
//            }
//        }
//        else {
//            print("Bundle path not found")
//        }

        return nil
    }

    public func getAllVersions(completionHandler: @escaping(NSDictionary) -> Void) {
        //        let url = URL(string: "\(ENDPOINT_URL)/versions.json")

        URLSession.shared.dataTask(with: self.versionsRegisterURL, completionHandler: {(data, response, error) in
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
}
