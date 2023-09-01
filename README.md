# Selene

`Selene` is generating obfuscated code for secret Key/Value

https://nshipster.com/secrets/

## Sample

<details><summary>GeneratedFile.swift</summary>

```swift
import Algorithms
import Foundation

public enum SecretEnv {
  static private let cipher: [UInt8] = [
    0xbe, 0xfe, 0x73, 0xe5, 0xaf, 0x1b, 0x5d, 0xe, 0xae, 0x22, 0x6a, 0x19, 0xcc, 0xdb, 0x9, 0x96,
    0x33, 0xbf, 0x4c, 0x48, 0x6b, 0x47, 0xf, 0x50, 0x75, 0x93, 0x7e, 0x6b, 0x6e, 0x4a, 0x64, 0xed,
    0x3c, 0x67, 0x6d, 0xff, 0x20, 0x3f, 0x82, 0x75, 0x29, 0x50, 0x9d, 0x5, 0x8a, 0xd3, 0x3c, 0x88,
    0xc, 0x82, 0xe, 0xb5, 0xcd, 0x46, 0x6a, 0x42, 0x1, 0xff, 0xd2, 0x28, 0xc9, 0xc3, 0x99, 0x5c,
  ]
  static private let _clientSecret: [UInt8] = [0x8c, 0xcc, 0x41, 0xd7]
  static private let _clientID: [UInt8] = [0x8f, 0xcf, 0x42, 0xd4]
  static public var clientSecret: String {
    string(data: _clientSecret, cipher: cipher)
  }
  static public var clientID: String {
    string(data: _clientID, cipher: cipher)
  }
  static private func string(data: [UInt8], cipher: [UInt8]) -> String {
    String.init(decoding: encodeData(data: data, cipher: cipher), as: UTF8.self)
  }
  static private func encodeData(data: [UInt8], cipher: [UInt8]) -> [UInt8] {
    data.indexed().map { offset, element in
      return element ^ cipher[offset % cipher.count]
    }
  }
}
```

</details>

```swift
print(SecretEnv.clientID)
```

## Adding Selene as a Dependency

To use the `Selene` plugin in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/zunda-pixel/selene", from: "1.1.0"),
```

## Use Selene on XcodeCloud

1. add swift-algorithms as a Dependency

```swift
.package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
```

2. set Secret Key/Value on Xcode Cloud `Environment Variable`

<img width="500" alt="xcode-cloud-environment-sample" src="https://github.com/zunda-pixel/GenEnvCode/assets/47569369/09753556-f470-4ecd-b1e5-3aa00fa1f81f">

3. add ci_scripts/ci_post_clone.sh [Apple Documents](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)

```shell
#!/bin/sh

# ci_post_clone.sh

# install Selene
brew tap zunda-pixel/selene
brew install zunda-pixel/selene/selene

# change directory to project top from ci_scripts
cd ..

## set Key/Value as Step 2

cat > .env <<EOL
clientID=${CLIENT_ID}
clientSecret=${CLIENT_SECRET}
EOL

selene {namespace(ex: SecretEnv)} .env {path/to/GeneratingEnv.swift}
# Ex. selene SecretEnv .env /Sources/Env/SecretEnv.swift
```

4. use Secert Value in Project

```swift
print({set namespace}.clientID)
print(SecretEnv.clientID)
print(SecretEnv.clientSecret)
```

## Use Selene on Local

> **Warning**
> *DO NOT COMMIT GENERATED CODE*

1. add swift-algorithms as a Dependency

```swift
.package(url: "https://github.com/zunda-pixel/selene", from: "1.1.0"),
```

2. install Selene

```shell
brew tap zunda-pixel/selene
brew install zunda-pixel/selene/selene
```

3. add `.env` file

```txt
key1=value1
#comment
key2=value2
key3=value3=value3
```

4. execute `Selene`

```shell
selene {namespace(ex: SecretEnv)} {path/to/env_file} {path/to/GeneratingEnv.swift}
# Ex. selene SecretEnv .env SecretEnv.swift
```

5. use Secret Value in Project

```swift
print({set namespace}.clientID)
print(SecretEnv.clientID)
print(SecretEnv.clientSecret)
```
