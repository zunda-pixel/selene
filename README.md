# GenEnvCode

`GenEnvCode` is generating obfuscated code for Secure Key/Value

## Adding GenEnvCode as a Dependency

To use the `GenEnvCode` plugin in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/zunda-pixel/GenEnvCode", from: "1.0.0"),
```

## Use GenEnvCode on XcodeCloud

1. add GenEnvCode as a Dependency
2. set Secure Key/Value on Xcode Cloud Environment

/var/folders/ss/4j4m9qr121x1nrl9kf3c_n7h0000gn/T/TemporaryItems/NSIRD_screencaptureui_0Ik0R2/screenshot-2023-08-29-22.13.38.png

3. add ci_scripts/ci_post_clone.sh

```shell
#!/bin/sh

# ci_post_clone.sh

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

cd ..

env_file=".env"
touch $env_file

## set key/value as Step 2

cat > $env_file <<EOL
clientID=${CLIENT_ID}
clientSecret=${CLIENT_SECRET}
EOL

projectPath=$(pwd)

cd path/to/Directory/on/Package.swift

swift package plugin --allow-writing-to-directory Sources generate-env ../${env_file} path/to/Env.swift
```

4. use Secure Key/Value in Project

```swift
print(Env.clientID)
print(Env.clientSecret)
```
