//
//  Main.swift
//  BetelgeuseSwiftSDK
//
//  Created by gabriel troia on 10/3/17.
//  Copyright © 2017 Betelgeuse. All rights reserved.
//


// Next Steps:

// 
// - Persist the last cached version to be able to load it
// - Determine what event triggers the checkFor Updates/Install methods
// - Determine where to store the data
//   Look into:
//    https://stackoverflow.com/questions/28628225/how-to-save-local-data-in-a-swift-app
//    http://www.raywenderlich.com/85578/first-core-data-app-using-swift
//

// Steps Done:

// - Load the next version and save it locally for the next usage
// - download the data corresponding to the best version
// - compare the current one with them and determine the best version
// - determine a mechanism to be able to import the cocoapod into any client-app as easy as possible
//      - Came up with the solution of dividing the SDK into 2 parts. One is teh actual SDK, very genric
//          the other is a wrapper that knows how to initialize it using the correct variables.
//      - The Actual SDK leaves in it's own git repo, while the Wrapper get's generated each time by betelgeuse
//          - Now that I'm thinking of it, the template cpuld actually leave on the same repo, under a "wrapper" dir
// - download all versions


import Foundation

public class Betelgeuse {
    private let repoName: String
    private let localDataBundleUrl: URL
    private let localFileName: String
    private let localFileExtension: String
    private let remoteDataBaseUrl: URL
    private let remoteDataPath: String
    private let versionsRegisterURL: URL
    private let updateDataVersion: (String) -> Void

    // There is a distinction between the 2 because the Schema is fixed while the Data is not
    private let currentSchemaVersion: Version
    // The Data Version is at least same as the Schema Version or larger
    private let currentDataVersion: Version

    public init(
        repoName: String,
        localDataBundleUrl: URL,
        localFileName: String,
        localFileExtension: String,
        remoteDataBaseUrl: URL,
        remoteDataPath: String,
        versionsRegisterUrl: URL,
        currentSchemaVersion: String,
        updateDataVersion: @escaping(String) -> Void
        ) {

        self.repoName = repoName
        self.localDataBundleUrl = localDataBundleUrl
        self.localFileName = localFileName
        self.localFileExtension = localFileExtension
        self.remoteDataBaseUrl = remoteDataBaseUrl
        self.remoteDataPath = remoteDataPath
        self.versionsRegisterURL = versionsRegisterUrl
        self.updateDataVersion = updateDataVersion

        self.currentSchemaVersion = Version(fromString: currentSchemaVersion)
        self.currentDataVersion = Version(fromString: currentSchemaVersion) // change later

        print("Instantiating Betelgeuse for \(repoName) with Schema Version: v\(currentSchemaVersion)")
//        readLocalFile(name: )

        // TODO: Add Validation
        //  If the currentDataVersion somehow is smaller than the currentSchemaVersion
        //  it means that data somehow got corrupted, and it should fallback to using the original Data.json

        checkForUpdates(completionHandler: { bestVersion in
            self.loadData(version: bestVersion, completionHandler: { (data) in
                print("json data")
                print(data)

                self.updateDataVersion(bestVersion.toString())

//                self.writeLocalFile(to: "\(repoName)_Data_v\(bestVersion.toString()).plist", data: data)
//                self.readLocalFile(name: "\(repoName)_Data_v\(bestVersion.toString()).plist")
            })
        })
    }

    private func checkForUpdates(completionHandler: @escaping(Version) -> Void) {
        getAllVersions(completionHandler: ({ data in
            let allVersions = data.allKeys.map({ s in
                return Version(fromString: s as! String)
            })

            if let bestVersion = Version.getBestVersion(currentVersion: self.currentDataVersion, versions: allVersions) {
                print("Best Version found: \(bestVersion.toString())")

                completionHandler(bestVersion)
            }
            else {
                print("No unbreaking changes on your current version \(self.currentDataVersion)")
            }
        }))
    }

    private func saveCurrentDataVersion(v: Version) {
        let dict: NSDictionary = [
            "version": v.toString(),
            "updated_at": "now"
        ]

        writeLocalFile(to: "DataVersion", data: dict)
    }

//    private func getCurrentDataVersion() -> Version {
//        return
//    }

    private func loadData(version: Version, completionHandler: @escaping(NSDictionary) -> Void) {
        if let url = URL(string: "\(self.remoteDataBaseUrl)/v\(version.toString())/\(self.remoteDataPath)") {
            self.loadData(fromUrl: url, completionHandler: completionHandler)
        }
        else {
            print("Bad Url")
        }
    }

    public func getModel() -> NSDictionary? {
        return loadDataFromOriginalFile();
    }

    private func loadDataFromOriginalFile() -> NSDictionary? {
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

    private func getAllVersions(completionHandler: @escaping(NSDictionary) -> Void) {
        loadData(fromUrl: versionsRegisterURL, completionHandler: completionHandler)
    }

    private func loadData<T>(fromUrl: URL, completionHandler: @escaping(T) -> Void) {
        print("Loading data from \(fromUrl.absoluteURL)")

        URLSession.shared.dataTask(with: fromUrl, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                //                print(error)
                return
            }
            if let jsonResult = try? JSONSerialization.jsonObject(
                with: data,
                options: JSONSerialization.ReadingOptions.mutableContainers
                ) as! T {
                return completionHandler(jsonResult)
            } else {
                print("Error in reading the json")
            }
        }).resume()
    }

//    public func readPlist(from: URL) -> NSDictionary {
//        return NSDictionary(contentsOf: from)
//    }

    private func readLocalFile(name: String) {
        let localUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let fileUrl = localUrl.appendingPathComponent(name)

        print("read file from \(fileUrl.absoluteURL)")
        let dict = NSDictionary(contentsOf: fileUrl);

        print("Reading \(dict)")
    }

    private func writeLocalFile(to: String, data: NSDictionary) {
        let localUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let fileUrl = localUrl.appendingPathComponent(to)

        data.write(to: fileUrl, atomically: true)
        print("Saved file \(fileUrl.absoluteURL)")
    }
}
