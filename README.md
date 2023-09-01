# Selene

`Selene` is generating obfuscated code for Secure Key/Value

## Adding Selene as a Dependency

To use the `Selene` plugin in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/zunda-pixel/selene", from: "1.1.0"),
```

## Use Selene on XcodeCloud

1. add Selene as a Dependency
2. set Secure Key/Value on Xcode Cloud `Environment Variable`

<img width="500" alt="xcode-cloud-environment-sample" src="https://github.com/zunda-pixel/GenEnvCode/assets/47569369/09753556-f470-4ecd-b1e5-3aa00fa1f81f">

3. add ci_scripts/ci_post_clone.sh [Apple Documents](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)

```shell
#!/bin/sh

# ci_post_clone.sh

defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

cd ..

env_file=".env"
touch $env_file

## set Key/Value as Step 2

cat > $env_file <<EOL
clientID=${CLIENT_ID}
clientSecret=${CLIENT_SECRET}
EOL

cd path/to/directory/on/Package.swift

swift package plugin --allow-writing-to-directory path/to/directory/on/file generate-env-code {namespace(ex: Env)} {path/to/env_file} {path/to/GeneratingEnv.swift}
```

4. use Secure Value in Project

```swift
print({set namespace}.clientID)
print(Env.clientID)
print(Env.clientSecret)
```
