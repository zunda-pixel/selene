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

    let cipher: [UInt8] = (0..<64).map { _ in
      UInt8.random(in: UInt8.min...UInt8.max)
    }
    
    let source = source(namespace: namespace, cipher: cipher, envValues: environmentValues)
    
    let fileData = Data(source.formatted().description.utf8)

    try fileData.write(to: outputFilePath)
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
    ArrayElementList {
      for element in elements {
        ArrayElement(expression: IntegerLiteralExprSyntax(digits: .identifier(String(format: "0x%x", element))))
      }
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
    modifiers: .init(arrayLiteral: .init(name: Token.static), .init(name: Token.private)),
    letOrVarKeyword: Token.let,
    bindings: .init(itemsBuilder: {
      PatternBinding(
        pattern: PatternSyntax(stringLiteral: "_\(key)"),
        typeAnnotation: TypeAnnotation(
          type: TypeSyntax("[UInt8]")
        ),
        initializer: InitializerClauseSyntax(value: arrayExpr(elements: encodedData))
      )
    })
  )
}

func publicKeyVariableKey(key: String) -> VariableDeclSyntax {
  VariableDeclSyntax(
    modifiers: .init(arrayLiteral: .init(name: Token.static), .init(name: Token.public)),
    letOrVarKeyword: Token.var,
    bindings: .init(itemsBuilder: {
      PatternBinding(
        pattern: PatternSyntax(stringLiteral: key),
        typeAnnotation: TypeAnnotation(
          type: TypeSyntax("String")
        ),
        accessor: .getter(CodeBlock {
          FunctionCallExpr(callee: IdentifierExprSyntax("string")) {
            TupleExprElementSyntax(
              label: .identifier("data"),
              colon: .colonToken(),
              expression: IdentifierExprSyntax(identifier: .identifier("_\(key)"))
            )
            TupleExprElementSyntax(
              label: .identifier("cipher"),
              colon: .colonToken(),
              expression: IdentifierExprSyntax(identifier: .identifier("cipher"))
            )
          }
        })
      )
    })
  )
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
    modifiers: .init(arrayLiteral: .init(name: Token.static), .init(name: Token.private)),
    letOrVarKeyword: Token.let,
    bindings: .init([
      PatternBindingSyntax(
        pattern: PatternSyntax(stringLiteral: "cipher"),
        typeAnnotation: TypeAnnotation(
          type: TypeSyntax("[UInt8]")
        ),
        initializer: .init(value: arrayExpr(elements: cipher))
      ),
    ])
  )
}

func stringFunction() -> some DeclSyntaxProtocol {
  FunctionDeclSyntax(
    modifiers: [DeclModifierSyntax(name: .static), DeclModifierSyntax(name: .private)],
    identifier: TokenSyntax.identifier("string"),
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
        returnType: SimpleTypeIdentifierSyntax(name: TokenSyntax.identifier("String"))
      )
    )
  ) {
    ReturnStmtSyntax(
      expression: FunctionCallExpr(callee: MemberAccessExpr(base: .init(stringLiteral: "String"), name: "init")) {
        TupleExprElementSyntax(
          label: .identifier("decoding"),
          colon: .colonToken(),
          expression: FunctionCallExpr(callee: MemberAccessExpr(dot: .identifier(""), name: "encodeData")) {
            TupleExprElementSyntax(
              label: .identifier("data"),
              colon: .colonToken(),
              expression: IdentifierExprSyntax(identifier: .identifier("data"))
            )
            TupleExprElementSyntax(
              label: .identifier("cipher"),
              colon: .colonToken(),
              expression: IdentifierExprSyntax(identifier: .identifier("cipher"))
            )
          }
        )
        TupleExprElementSyntax(
          label: .identifier("as"),
          colon: .colonToken(),
          expression: IdentifierExprSyntax(identifier: .identifier("UTF8.self"))
        )
      }
    )
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
