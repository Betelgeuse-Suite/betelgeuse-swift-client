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
    public var shared: Betelgeuse?
    
    private let repoName: String
    private let localDataBundleUrl: URL
    private let localFileName: String
    private let localFileExtension: String
    private let remoteDataBaseUrl: URL
    private let remoteDataPath: String
    private let versionsRegisterURL: URL

    // There is a distinction between the 2 because the Schema is fixed while the Data is not
    private let currentSchemaVersion: Version
    // The Data Version is at least same as the Schema Version or larger
    private let currentDataVersion: Version

    private let userDefaults: UserDefaults

    public init(
        repoName: String,
        localDataBundleUrl: URL,
        localFileName: String,
        localFileExtension: String,
        remoteDataBaseUrl: URL,
        remoteDataPath: String,
        versionsRegisterUrl: URL,
        currentSchemaVersion: String
        ) {
        self.userDefaults = UserDefaults.standard

        self.repoName = repoName
        self.localDataBundleUrl = localDataBundleUrl
        self.localFileName = localFileName
        self.localFileExtension = localFileExtension
        self.remoteDataBaseUrl = remoteDataBaseUrl
        self.remoteDataPath = remoteDataPath
        self.versionsRegisterURL = versionsRegisterUrl

        self.currentSchemaVersion = Version(fromString: currentSchemaVersion)
        self.currentDataVersion = Betelgeuse.getCurrentDataVersion(currentSchemaVersion: Version(fromString: currentSchemaVersion))
        
        
        // If the Data is not newer than the Schema (maybe because a new deploy) then reset the UserDefaults
        if !Version.isNewerThan(self.currentSchemaVersion, self.currentDataVersion) {
            resetUserDefaults()
        }
        

        print("Betelgeuse: Instantiating Betelgeuse for \(repoName) Bundle, Version(Schema: v\(self.currentSchemaVersion.toString()), Data: v\(self.currentDataVersion.toString()))")
    }
    
    private static func getCurrentDataVersion(currentSchemaVersion: Version) -> Version {
        // If the userDefault somehow changes, make sure you change it here
        // This code is a duplicate but for some dumb reason this method needs to be static
        let userDefaults = UserDefaults.standard
        
        if let cachedVersionString = userDefaults.string(forKey: "BetelgeuseCurrentDataVersion") {
            let cachedVersion = Version(fromString: cachedVersionString)
            
            print("is newere?")
            if Version.isNewerThan(currentSchemaVersion, cachedVersion) {
                print("apparently yes")
                return cachedVersion
            }
        }
        
        // Default to Current Schema Version
        return currentSchemaVersion
    }

    public func checkAndInstallUpdates() {
        // TODO: Add Validation
        //  If the currentDataVersion somehow is smaller than the currentSchemaVersion
        //  it means that data somehow got corrupted, and it should fallback to using the original Data.json
        
        checkForUpdates(completionHandler: { bestVersion in
            self.fetchData(version: bestVersion, completionHandler: { (dataAsDict) in
                self.install(version: bestVersion, data: dataAsDict);
            })
        })
    }
    
    public func getModel() -> NSDictionary? {
        if let cachedFileName = userDefaults.string(forKey: "BetelgeuseCurrentDataFileName") {
            if let data = readLocalFile(name: cachedFileName) {
                return data;
            }
        }

        // SideEffect: reset the user defaults besides returing the Original Model
//        resetUserDefaults();

        return loadDataFromOriginalFile();
    }
    
    private func resetUserDefaults() {
        self.userDefaults.removeObject(forKey: "BetelgeuseCurrentDataFileName")
        self.userDefaults.set(currentSchemaVersion.toString(), forKey: "BetelgeuseCurrentDataVersion")
        self.userDefaults.set("", forKey: "BetelgeuseCurrentDataFileName")

        print("Betelgeuse: Reset userDefaults.")
    }

    /*
     * Downloads the Data file to the local cache, names it based on the given Version 
     * and Persists the new Version as the Data Version
     */
    private func install(version: Version, data: NSDictionary) {
        print("Betelgeuse: Installing version \(version.toString())...")
        
        let fileName = "\(repoName)_Data_v\(version.toString()).plist"
        self.writeLocalFile(name: fileName, data: data)

        self.userDefaults.set(version.toString(), forKey: "BetelgeuseCurrentDataVersion")
        self.userDefaults.set(fileName, forKey: "BetelgeuseCurrentDataFileName")
    }

    private func checkForUpdates(completionHandler: @escaping(Version) -> Void) {
        print("Betelgeuse: Checking for data updates (current \(self.currentDataVersion.toString()))...")
        getAllVersions(completionHandler: ({ data in
            let allVersions = data.allKeys.map({ s in
                return Version(fromString: s as! String)
            })

            if let bestVersion = Version.getBestVersion(currentVersion: self.currentDataVersion, versions: allVersions) {
                print("Betelgeuse: Newer version found: \(bestVersion.toString())")

                completionHandler(bestVersion)
            }
            else {
                print("Betelgeuse: No data updates found!")
            }
        }))
    }

    private func fetchData(version: Version, completionHandler: @escaping(NSDictionary) -> Void) {
        if let url = URL(string: "\(self.remoteDataBaseUrl)/v\(version.toString())/\(self.remoteDataPath)") {
            self.loadData(fromUrl: url, completionHandler: completionHandler)
        }
        else {
            print("Betelgeuse: Bad Version Url")
        }
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
                        print("Betelgeuse: Use the Original Data.json File")
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
        print("Betelgeuse: Fetching data from \(fromUrl.absoluteURL)")

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
                print("Betelgeuse: Error in reading the json")
            }
        }).resume()
    }

    private func readLocalFile(name: String) -> NSDictionary? {
        let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileUrl = localUrl.appendingPathComponent(name)

        print("Betelgeuse: Reading file from \(fileUrl.absoluteURL)...")
        return NSDictionary(contentsOf: fileUrl);
    }

    private func writeLocalFile(name: String, data: NSDictionary) {
        let localUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileUrl = localUrl.appendingPathComponent(name)
        
        print("Betelgeuse: Saving file \(fileUrl.absoluteURL)...")
        data.write(to: fileUrl, atomically: true)
    }
}
