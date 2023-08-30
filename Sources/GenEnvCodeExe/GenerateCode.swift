import Foundation
import Algorithms
import SwiftSyntax
import SwiftSyntaxBuilder
import ArgumentParser

@main
struct GenerateCode: ParsableCommand {
  @Argument(help: "Generating Namespace(ex: SecureEnv).")
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
  let lines = content.split(whereSeparator: \.isNewline)

  let environmentValues: [String: String] = lines.reduce(into: [:]) { dictionary, line in
    let values = line.split(separator: "=")
    let key = String(values[0])
    let value = String(values[1])
    dictionary[key] = value
  }
  
  return environmentValues
}

func arrayExpr(elements: [UInt8]) -> some ExprSyntaxProtocol {
  ArrayExprSyntax {
    for element in elements {
      ArrayElementSyntax(expression: IntegerLiteralExprSyntax(literal: .identifier(String(format: "0x%x", element))))
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
    name: PatternSyntax("_\(raw: key)"),
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
      pattern: PatternSyntax(stringLiteral: key),
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
      ImportDeclSyntax(path: AccessPathSyntax([AccessPathComponentSyntax(name: name)]))
    }
    
    EnumDeclSyntax(
      modifiers: [DeclModifierSyntax(name: .public)],
      identifier: namespace
    ) {
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
  }
}

func cipherVariable(cipher: [UInt8]) -> some DeclSyntaxProtocol {
  VariableDeclSyntax(
    modifiers: [
      DeclModifierSyntax(name: .keyword(.static)),
      DeclModifierSyntax(name: .keyword(.private))
    ],
    Keyword.let,
    name: PatternSyntax(stringLiteral: "cipher"),
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
            colon: .colonToken(),
            type: ArrayTypeSyntax(element: TypeSyntax("UInt8"))
          )
          FunctionParameterSyntax(
            firstName: TokenSyntax.identifier("cipher"),
            colon: .colonToken(),
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
      period: .periodToken(),
      name: .identifier("init")
    )) {
      LabeledExprSyntax(
        label: "decoding",
        colon: .colonToken(),
        expression: FunctionCallExprSyntax(callee: DeclReferenceExprSyntax(baseName: .identifier("encodeData"))) {
          LabeledExprSyntax(
            label: "data",
            colon: .colonToken(),
            expression: DeclReferenceExprSyntax(baseName: .identifier("data"))
          )
          LabeledExprSyntax(
            label: "cipher",
            colon: .colonToken(),
            expression: DeclReferenceExprSyntax(baseName: .identifier("cipher"))
          )
        }
      )
      LabeledExprSyntax(
        label: "as",
        colon: .colonToken(),
        expression: DeclReferenceExprSyntax(baseName: .identifier("UTF8.self"))
      )
    }
  }
}

func encodeDataFunction() -> some DeclSyntaxProtocol {
  FunctionDeclSyntax(
    modifiers: [DeclModifierSyntax(name: .static), DeclModifierSyntax(name: .private)],
    identifier: TokenSyntax.identifier("encodeData"),
    signature: FunctionSignatureSyntax(
      input: ParameterClauseSyntax(
        parameterList: FunctionParameterListSyntax {
          FunctionParameterSyntax(
            firstName: TokenSyntax.identifier("data"),
            colon: .colonToken(),
            type: TypeSyntax("[UInt8]")
          )
          FunctionParameterSyntax(
            firstName: TokenSyntax.identifier("cipher"),
            colon: .colonToken(),
            type: TypeSyntax("[UInt8]")
          )
        }
      ),
      output: ReturnClauseSyntax(
        returnType: SimpleTypeIdentifierSyntax(name: TokenSyntax.identifier("[UInt8]"))
      )
    )
  ) {
    FunctionCallExprSyntax(
      calledExpression: MemberAccessExprSyntax(
        base: .init(FunctionCallExprSyntax(
          calledExpression: MemberAccessExprSyntax(
            base: .init(stringLiteral: "data"),
            name: "indexed"
          ),
          leftParen: .identifier("("),
          rightParen: .identifier(")")
        )),
        name: "map"
      ),
      trailingClosure: ClosureExprSyntax(
        signature: .init(
          input: .simpleInput(.init([
            .init(name: .identifier("offset"), trailingComma: .commaToken(trailingTrivia: .space)),
            .init(name: .identifier("element"))
          ])),
          inTok: .inKeyword(leadingTrivia: .space)
        ),
        statements: CodeBlockItemListSyntax {
          ReturnStmtSyntax(
            expression: SequenceExprSyntax {
              ExprListSyntax {
                IdentifierExprSyntax(identifier: .identifier("element"))
                BinaryOperatorExprSyntax(operatorToken: TokenSyntax.identifier("^"))
                SubscriptExprSyntax(
                  calledExpression: IdentifierExprSyntax(identifier: .identifier("cipher")),
                  argumentList: TupleExprElementListSyntax([.init(expression: SequenceExprSyntax {
                    ExprListSyntax {
                      IdentifierExprSyntax(identifier: .identifier("offset"))
                      BinaryOperatorExprSyntax(operatorToken: TokenSyntax.spacedBinaryOperator("%"))
                      MemberAccessExprSyntax(base: .init(stringLiteral: "cipher"), name: "count")
                    }
                  })])
                )
              }
            }
          )
        }
      )
    )
  }
}
