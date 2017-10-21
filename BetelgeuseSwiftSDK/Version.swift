//
//  Version.swift
//  BetelgeuseBundleDemo
//
//  Created by gabriel troia on 10/16/17.
//

import Foundation

public class Version {
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
    
    public static func isEqualTo(_ a: Version, _ b: Version) -> Bool {
        return b.major == a.major
            || b.major == a.major && b.minor == a.minor
            || b.major == a.major && b.minor == a.minor && b.patch == a.patch
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
