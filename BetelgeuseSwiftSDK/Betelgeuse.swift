//
//  Main.swift
//  BetelgeuseSwiftSDK
//
//  Created by gabriel troia on 10/3/17.
//  Copyright © 2017 Betelgeuse. All rights reserved.
//

import Foundation

public class Betelgeuse {
    private let localDataBundleUrl: URL
    private let localFileName: String
    private let localFileExtension: String
    private let remoteDataUrl: URL
    private let versionsRegisterURL: URL
    private let currentVersion: String // Version type

    public init(
        localDataBundleUrl: URL,
        localFileName: String,
        localFileExtension: String,
        remoteDataUrl: URL,
        versionsRegisterUrl: URL,
        currentVersion: String) {

        self.localDataBundleUrl = localDataBundleUrl
        self.localFileName = localFileName
        self.localFileExtension = localFileExtension
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
    public func getModel() -> NSDictionary? {
        return loadDataFromFile();
    }

    private func loadDataFromFile() -> NSDictionary? {
        if let dataBundle = Bundle(url: self.localDataBundleUrl) {
            if let path = dataBundle.path(forResource: self.localFileName, ofType: self.localFileExtension) {
                if let jsonData = try? NSData(
                    contentsOfFile: path,
                    options: NSData.ReadingOptions.mappedIfSafe
                    ) {
                    if let jsonResult: NSDictionary = try? JSONSerialization.jsonObject(
                        with: jsonData as Data,
                        options: JSONSerialization.ReadingOptions.mutableContainers
                        ) as! NSDictionary {
                        print("Betelgeuse: Succefully loaded the local data")
                        return jsonResult
                    }
                    else {
                        print("Betelgeuse: Not a valid json")
                    }
                }
                else {
                    print("Betelgeuse: Cannot read data from file")
                }
            }
            else {
                print("Betelgeuse: Path not found")
            }
        }
        else {
            print("Betelgeuse: Bundle URL not found")
        }

        return nil
    }

    public func getAllVersions(completionHandler: @escaping(NSDictionary) -> Void) {
        //        let url = URL(string: "\(ENDPOINT_URL)/versions.json")

        URLSession.shared.dataTask(with: self.versionsRegisterURL, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
//                print(error)
                return
            }
            if let jsonResult = try? JSONSerialization.jsonObject(
                with: data,
                options: JSONSerialization.ReadingOptions.mutableContainers
                ) as! NSDictionary {
                return completionHandler(jsonResult)
            } else {
                print("Error in reading the json")
            }
        }).resume()
    }
}
