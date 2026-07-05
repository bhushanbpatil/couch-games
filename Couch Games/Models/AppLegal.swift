//
//  AppLegal.swift
//  Couch Games
//

import Foundation

enum AppLegal {
    /// Host this file on GitHub (or your site) and paste the same URL into App Store Connect.
    static let privacyPolicyURL = URL(string: "https://github.com/bhushanbpatil/couch-games/blob/main/PRIVACY.md")!

    static let supportURL = URL(string: "https://github.com/bhushanbpatil/couch-games/issues")!

    static let supportEmail = "bhushanbpatil8@gmail.com"

    static var supportEmailURL: URL {
        URL(string: "mailto:\(supportEmail)?subject=Couch%20Games%20Support")!
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
