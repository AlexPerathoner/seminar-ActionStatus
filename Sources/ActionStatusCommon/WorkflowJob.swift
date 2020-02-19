// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

class Job: Option {
    enum Platform {
        case mac
        case linux
    }
    
    let swift: String?
    let platform: Platform
    let includeXcode: Bool
    
    func yaml(build: Bool, test: Bool, notify: Bool, upload: Bool, package: String, configurations: [String]) -> String {
        var yaml =
            """
            \(id):
                name: \(name)
            
            """
        
        switch (platform) {
            case .mac:
            yaml.append(
            """
                runs-on: macOS-latest

            """
            )
            
            case .linux:
                let swift = self.swift ?? "5.1"
                yaml.append(
            """
                runs-on: ubunu-latest
                container: swift:\(swift)

            """
                )
        }
        
        yaml.append(
            """
                steps:
                - name: Checkout
                  uses: actions/checkout@v1
                - name: Swift Version
                  run: swift --version
                - name: Xcode Version
                  run: xcodebuild -version
                - name: XC Pretty
                  run: sudo gem install xcpretty-travis-formatter
                - name: Make Logs Directory
                  run: mkdir logs
            """
        )

        if build {
            for config in configurations {
                yaml.append(
                    """
                        - name: Build (\(config))
                          run: swift build -v -c \(config.lowercased())

                    """
                )
            }
        }

        if test {
            for config in configurations {
                let extraArgs = config == "Release" ? "-Xswiftc -enable-testing" : ""
                yaml.append(
                    """
                        - name: Test (\(config))
                          run: swift test -v -c \(config.lowercased()) \(extraArgs)

                    """
                )
            }
        }

        if includeXcode {
            if build {
                for config in configurations {
                    yaml.append(
                        """
                            - name: Build (iOS/\(config))
                              run: xcodebuild clean build -workspace . -scheme \(package) -destination "name=iPad Pro (11-inch) -configuration \(config)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | tee logs/xcodebuild-ios-build-\(config.lowercased()).log | xcpretty

                        """
                    )
                }
            }

            if test {
                for config in configurations {
                    yaml.append(
                        """
                            - name: Test (iOS/\(config))
                              run: xcodebuild test -workspace . -scheme \(package) -destination "name=iPad Pro (11-inch)" -configuration \(config) CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | tee logs/xcodebuild-ios-test-\(config.lowercased()).log | xcpretty

                        """
                    )
                }
            }
        }

        if upload {
            yaml.append(
                """
                    - name: Upload Logs
                      uses: actions/upload-artifact@v1
                      with:
                        name: logs
                        path: logs

                """
            )
        }


        if notify {
            yaml.append(
                """
                    - name: Slack Notification
                      uses: elegantchaos/slatify@master
                      if: always()
                      with:
                        type: ${{ job.status }}
                        job_name: '\(name)'
                        mention_if: 'failure'
                        url: ${{ secrets.SLACK_WEBHOOK }}

                """
            )
        }

        yaml.append("\n\n")
        
        return yaml
    }
    
    init(_ id: String, name: String, platform: Platform = .linux, swift: String? = nil, includeXcode: Bool = false) {
        self.platform = platform
        self.swift = swift
        self.includeXcode = includeXcode
        super.init(id, name: name)
    }
}
