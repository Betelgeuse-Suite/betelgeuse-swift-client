//
//  Main.swift
//  BetelgeuseSwiftSDK
//
//  Created by gabriel troia on 10/3/17.
//  Copyright © 2017 Betelgeuse. All rights reserved.
//

import Foundation

class Version {
    private let major: Int
    private let minor: Int
    private let patch: Int

    init(fromString: String) {
        let fromArray = fromString.components(separatedBy: ".")

        // Add validation

        self.major = Int(fromArray[0]) ?? -1
        self.minor = Int(fromArray[1]) ?? -1
        self.patch = Int(fromArray[2]) ?? -1
    }

    public func toString() -> String {
        return "\(major).\(minor).\(patch)"
    }

    public static func sortDesc(_ versions: [Version]) -> [Version] {
        return versions.sorted(by: {a, b in
            return isNewerThan(b, a)
        })
    }

    public static func isNewerThan(_ a: Version, _ b: Version) -> Bool {
        return b.major > a.major
            || b.major == a.major && b.minor > a.minor
            || b.major == a.major && b.minor == a.minor && b.patch > a.patch
    }

    public static func isNonBreakingRelease(_ a: Version, _ b: Version) -> Bool {
        return a.major == b.major
    }

    public static func getBestVersion(currentVersion: Version, versions: [Version]) -> Version? {
        let bestVersions = sortDesc(onlyNonBreakingAndNewer(than: currentVersion, versions))

        if bestVersions.count > 0 {
            return bestVersions[0]
        }

        return nil
    }

    public static func onlyNonBreakingAndNewer(than version: Version, _ versions: [Version]) -> [Version] {
        return versions.filter({ nextVersion -> Bool in
            return isNonBreakingRelease(version, nextVersion) && isNewerThan(version, nextVersion)
        });
    }
}

public class Betelgeuse {
    private let localDataBundleUrl: URL
    private let localFileName: String
    private let localFileExtension: String
    private let remoteDataUrl: URL
    private let versionsRegisterURL: URL
    private let currentVersion: Version // Version type

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
        self.currentVersion = Version(fromString: currentVersion) // todo -> Version Type

        getAllVersions(completionHandler: ({ data in
            let allVersions = data.allKeys.map({ s in
                return Version(fromString: s as! String)
            })

            Version.sortDesc(allVersions).forEach({ (v) in
                print(v.toString())
            })

            if let bestVersion = Version.getBestVersion(currentVersion: self.currentVersion, versions: allVersions) {
                print("Best Version: \(bestVersion.toString())")
            }
            else {
                print("No unbreaking changes on your current version \(currentVersion)")
            }

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
        print("Loading all versions from \(self.versionsRegisterURL)")
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
