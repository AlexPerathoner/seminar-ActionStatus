// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Bundles

public class Generator {
    public struct Output {
        public let repo: Repo
        public let source: String
        public let data: Data
        public let header: String
        public let delimiter: String
    }

    public let compilers = [
        Compiler("swift-50", name: "Swift 5.0", short: "5.0", linux: "swift:5.0", mac: .xcode(version: "11.2.1")),
        Compiler("swift-51", name: "Swift 5.1", short: "5.1", linux: "swift:5.1", mac: .xcode(version: "11.3.1")),
        Compiler("swift-52", name: "Swift 5.2", short: "5.2", linux: "swift:5.2.3-bionic", mac: .xcode(version: "11.4")),
        Compiler("swift-53", name: "Swift 5.3", short: "5.3", linux: "swift:5.3.3-bionic", mac: .xcode(version: "12.3")),
        Compiler("swift-54", name: "Swift 5.4 Nightly", short: "5.4", linux: "swiftlang/swift:nightly-5.4-bionic", mac: .toolchain(version: "12_beta", branch: "swift-5.4-branch")),
        Compiler("swift-nightly", name: "Swift Development Nightly", short: "dev", linux: "swiftlang/swift:nightly", mac: .toolchain(version: "12_beta", branch: "development")),
    ]
    
    public let platforms = [
        Platform("macOS", name: "macOS"),
        Platform("macOS-xcode", name: "macOS", xcodeDestination: ""),
        Platform("iOS", name: "iOS", xcodeDestination: "iPhone 11"),
        Platform("tvOS", name: "tvOS", xcodeDestination: "Apple TV"),
        Platform("watchOS", name: "watchOS", xcodeDestination: "Apple Watch Series 5 - 44mm"),
        Platform("linux", name: "Linux"),
    ]
    
    public let configurations = [
        Option("debug", name: "Debug"),
        Option("release", name: "Release")
    ]
    
    public let general = [
        Option("build", name: "Perform Build"),
        Option("test", name: "Run Tests"),
        Option("firstlast", name: "Use Oldest and Newest Swift Only"),
        Option("notify", name: "Post Notifications"),
        Option("upload", name: "Upload Logs"),
        Option("header", name: "Add a header to README.md")
    ]
    
    public init() {
    }
    
    func enabledCompilers(for repo: Repo) -> [Compiler] {
        let options = repo.settings.options
        var enabled: [Compiler] = []
        for swift in compilers {
            if options.contains(swift.id) {
                enabled.append(swift)
            }
        }
        return enabled
    }
    
    func enabledPlatforms(for repo: Repo) -> [Platform] {
        let options = repo.settings.options
        var jobs: [Platform] = []
        for platform in platforms {
            if options.contains(platform.id) {
                jobs.append(platform)
            }
        }
        
        return jobs
    }

    func enabledConfigs(for repo: Repo) -> [String] {
        let options = repo.settings.options
        return configurations.filter({ options.contains($0.id) }).map({ $0.name })
    }

    public func toggleSet(for options: [Option], in settings: WorkflowSettings) -> [Bool] {
        var toggles: [Bool] = []
        for option in options {
            toggles.append(settings.options.contains(option.id))
        }
        return toggles
    }
    
    public func enabledIdentifiers(for options: [Option], toggleSet toggles: [Bool]) -> [String] {
        var identifiers: [String] = []
        for n in 0 ..< options.count {
            if toggles[n] {
                identifiers.append(options[n].id)
            }
        }
        return identifiers
    }
    
    func generateYAML(for repo: Repo, platforms: [Platform], compilers: [Compiler], application: BundleInfo) -> String {
        
        var source =
         """
         # --------------------------------------------------------------------------------
         # This workflow was automatically generated by Action Status \(application.fullVersionString).
         # (see https://actionstatus.elegantchaos.com for more details)
         # --------------------------------------------------------------------------------
         
         name: \(repo.workflow)
         
         on: [push, pull_request]
         
         jobs:
         
         """
         
        var xcodePlatforms: [Platform] = []
        for platform in platforms {
            if platform.xcodeDestination == nil {
                source.append(platform.yaml(repo: repo, compilers: compilers, configurations: enabledConfigs(for: repo)))
            } else {
                xcodePlatforms.append(platform)
            }
        }
        
        if xcodePlatforms.count > 0 {
            let xcodePlatform = Platform("xcode", name: "Xcode", subPlatforms: xcodePlatforms)
            source.append(xcodePlatform.yaml(repo: repo, compilers: compilers, configurations: enabledConfigs(for: repo)))
        }
        
        return source
    }
     
     func generateHeader(for repo: Repo, platforms: [Platform], compilers: [Compiler], application: BundleInfo) -> (String, String) {
         var header = ""
         let headerDelimiter = "[comment]: <> (End of ActionStatus Header)\n\n"
         if repo.settings.header {
             let platformNames = platforms.map({ $0.name }).joined(separator: ", ")
             let platformIDs = platforms.map({ $0.name })
             let swiftBadges = compilers.map({ "![swift \($0.short) shield]" }).joined(separator: " ")
             let swiftShields = compilers.map({ "[swift \($0.short) shield]: \(repo.imgShieldURL(for: $0)) \"Swift \($0.short)\"" }).joined(separator: "\n")

             header += """
                 [comment]: <> (Header Generated by ActionStatus \(application.versionString) - \(application.build))
                 
                 [![Test results][tests shield]][actions] [![Latest release][release shield]][releases] [\(swiftBadges)][swift] ![Platforms: \(platformNames)][platforms shield]

                 [release shield]: \(repo.imgShieldURL(for: .release))
                 [platforms shield]: \(repo.imgShieldURL(forPlatforms: platformIDs)) "\(platformNames)"
                 [tests shield]: \(repo.githubURL(for: .badge("")))
                 \(swiftShields)

                 [swift]: https://swift.org
                 [releases]: \(repo.githubURL(for: .releases))
                 [actions]: \(repo.githubURL(for: .actions))

                 \(headerDelimiter)
                 """
         }
         
         return (header, headerDelimiter)
     }

    public func generateWorkflow(for repo: Repo, application: BundleInfo) -> Output? {
        var compilers = enabledCompilers(for: repo)
        if repo.settings.options.contains("firstlast") && (compilers.count > 0) {
            let first = compilers.first!
            let last = compilers.last!
            compilers = [first]
            if first != last {
                compilers.append(last)
            }
        }
        
        let platforms = enabledPlatforms(for: repo)

        let source = generateYAML(for: repo, platforms: platforms, compilers: compilers, application: application)
        let (header, delimiter) = generateHeader(for: repo, platforms: platforms, compilers: compilers, application: application)
        
        guard let data = source.data(using: .utf8) else { return nil }
        return Output(repo: repo, source: source, data: data, header: header, delimiter: delimiter)
    }
    
}
