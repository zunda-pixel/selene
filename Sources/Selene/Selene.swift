import Foundation
import Algorithms
import SwiftSyntax
import SwiftSyntaxBuilder
import ArgumentParser

@main
struct Selene: ParsableCommand {
  @Argument(help: "Generating Namespace(Ex: SecretEnv).")
  var namespace: String

  @Argument(help: "Env file path.")
  var envFilePath: String
  
  @Argument(help: "Output file path.")
  var outputFilePath: String
  
  mutating func run() throws {
    let envFilePath = URL(fileURLWithPath: self.envFilePath, isDirectory: false)
    let outputFilePath = URL(fileURLWithPath: self.outputFilePath, isDirectory: false)

    let envFileContent = try String(contentsOf: envFilePath)

    let environmentValues: [String: String] = environmentValues(content: envFileContent)

    let cipher: [UInt8] = generateCipher(count: 64)
    
    let source = source(namespace: namespace, cipher: cipher, envValues: environmentValues)
    
    let fileData = Data(source.formatted().description.utf8)

    try fileData.write(to: outputFilePath)
  }
}

func generateCipher(count: Int) -> [UInt8] {
  (0..<count).map { _ in
    UInt8.random(in: UInt8.min...UInt8.max)
  }
}

func environmentValues(content: String) -> [String: String] {
  let lines = content.split(whereSeparator: \.isNewline).filter {
    !$0.hasPrefix("#") // ignore comment out
  }

  let environmentValues: [String: String] = lines.reduce(into: [:]) { dictionary, line in
    let values = line.split(separator: "=", maxSplits: 1)
    guard let key = values[safe: 0],
          let value = values[safe: 1] else {
      return
    }
    dictionary[String(key)] = String(value)
  }
  
  return environmentValues
}

extension Array {
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

func arrayExpr(elements: [UInt8]) -> some ExprSyntaxProtocol {
  ArrayExprSyntax {
    for element in elements {
      ArrayElementSyntax(expression: IntegerLiteralExprSyntax(literal: .integerLiteral(String(format: "0x%x", element))))
    }
  }
}

func encodeData(_ data: [UInt8], cipher: [UInt8]) -> [UInt8] {
  data.indexed().map { offset, element in
    element ^ cipher[offset % cipher.count]
  }
}

func privateKeyVariableKey(key: String, value: String, cipher: [UInt8]) -> some DeclSyntaxProtocol {
  let data: Data = Data(value.utf8)
  let encodedData: [UInt8] = encodeData(Array(data), cipher: cipher)
  
  return VariableDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.private)),
    ],
    Keyword.let,
    name: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("_\(key)"))),
    type:  TypeAnnotationSyntax(
      type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
    ),
    initializer: InitializerClauseSyntax(value: arrayExpr(elements: encodedData))
  )
}

func publicKeyVariableKey(key: String) -> VariableDeclSyntax {
  VariableDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.public))
    ],
    bindingSpecifier: .keyword(.var)
  ) {
    PatternBindingSyntax(
      pattern: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(key))),
      typeAnnotation: TypeAnnotationSyntax(type: TypeSyntax("String")),
      accessorBlock: AccessorBlockSyntax(accessors: .getter(CodeBlockItemListSyntax {
        FunctionCallExprSyntax(callee: DeclReferenceExprSyntax(baseName: .identifier("string"))) {
          LabeledExprSyntax(
            label: .identifier("data"),
            colon: .colonToken(),
            expression: DeclReferenceExprSyntax(baseName: .identifier("_\(key)"))
          )
          LabeledExprSyntax(
            label: .identifier("cipher"),
            colon: .colonToken(),
            expression: DeclReferenceExprSyntax(baseName: .identifier("cipher"))
          )
        }
      }))
    )
  }
}

func source(namespace: String, cipher: [UInt8], envValues: [String: String]) -> SourceFileSyntax {
  SourceFileSyntax {
    for name in ["Algorithms", "Foundation"] {
      ImportDeclSyntax(
        path: ImportPathComponentListSyntax { ImportPathComponentSyntax(name: .identifier(name)) }
      )
    }
    
    EnumDeclSyntax(
      modifiers: [DeclModifierSyntax(name: .keyword(.public))],
      name: .identifier(namespace),
      memberBlock: MemberBlockSyntax {
        cipherVariable(cipher: cipher)
        
        for (key, value) in envValues {
          privateKeyVariableKey(key: key, value: value, cipher: cipher)
        }
        
        for item in envValues {
          publicKeyVariableKey(key: item.key)
        }
        
        stringFunction()
        
        encodeDataFunction()
      }
    )
  }
}

func cipherVariable(cipher: [UInt8]) -> some DeclSyntaxProtocol {
  VariableDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.private))
    ],
    Keyword.let,
    name: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier("cipher"))),
    type: TypeAnnotationSyntax(type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))),
    initializer: InitializerClauseSyntax(value: arrayExpr(elements: cipher))
  )
}

func stringFunction() -> some DeclSyntaxProtocol {
  FunctionDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.private)),
    ],
    name: .identifier("string"),
    signature: FunctionSignatureSyntax(
      parameterClause: FunctionParameterClauseSyntax(
        parameters: FunctionParameterListSyntax {
          FunctionParameterSyntax(
            firstName: TokenSyntax.identifier("data"),
            type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
          )
          FunctionParameterSyntax(
            firstName: TokenSyntax.identifier("cipher"),
            type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
          )
        }
      ),
      returnClause: ReturnClauseSyntax(
        type: IdentifierTypeSyntax(name: .identifier("String"))
      )
    )
  ) {
    FunctionCallExprSyntax(callee: MemberAccessExprSyntax(
      base: DeclReferenceExprSyntax(baseName: .identifier("String")),
      name: .identifier("init")
    )) {
      LabeledExprSyntax(
        label: "decoding",
        expression: FunctionCallExprSyntax(callee: DeclReferenceExprSyntax(baseName: .identifier("encodeData"))) {
          LabeledExprSyntax(
            label: "data",
            expression: DeclReferenceExprSyntax(baseName: .identifier("data"))
          )
          LabeledExprSyntax(
            label: "cipher",
            expression: DeclReferenceExprSyntax(baseName: .identifier("cipher"))
          )
        }
      )
      LabeledExprSyntax(
        label: "as",
        expression: DeclReferenceExprSyntax(baseName: .identifier("UTF8.self"))
      )
    }
  }
}

func encodeDataFunction() -> some DeclSyntaxProtocol {
  FunctionDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.private)),
    ],
    name: .identifier("encodeData"),
    signature: FunctionSignatureSyntax(
      parameterClause: FunctionParameterClauseSyntax {
        FunctionParameterSyntax(
          firstName: .identifier("data"),
          type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
        )
        FunctionParameterSyntax(
          firstName: .identifier("cipher"),
          type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
        )
      },
      returnClause: ReturnClauseSyntax(
        type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
      )
    )
  ) {
    FunctionCallExprSyntax(
      calledExpression: MemberAccessExprSyntax(
        base: FunctionCallExprSyntax(
          callee: MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .identifier("data")),
            name: "indexed"
          )
        ),
        name: "map"
      ),
      arguments: LabeledExprListSyntax([]),
      trailingClosure: ClosureExprSyntax(
        signature: ClosureSignatureSyntax(
          parameterClause: .simpleInput(
            ClosureShorthandParameterListSyntax {
              ClosureShorthandParameterSyntax(name: .identifier("offset"))
              ClosureShorthandParameterSyntax(name: .identifier("element"))
            }
          )
        ),
        statements: CodeBlockItemListSyntax {
          ReturnStmtSyntax(
            expression: SequenceExprSyntax {
              DeclReferenceExprSyntax(baseName: .identifier("element"))
              BinaryOperatorExprSyntax(text: "^")
              SubscriptCallExprSyntax(calledExpression: DeclReferenceExprSyntax(baseName: .identifier("cipher"))) {
                LabeledExprListSyntax([.init(expression: SequenceExprSyntax {
                  DeclReferenceExprSyntax(baseName: .identifier("offset"))
                  BinaryOperatorExprSyntax(text: "%")
                  MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier("cipher")),
                    name: "count"
                  )
                })])
              }
            }
          )
        }
      )
    )
  }
}
