import Foundation
import os
import Algorithms
import SwiftSyntax
import SwiftSyntaxBuilder

let envFilePathString = CommandLine.arguments[1]
let exportFilePathString = CommandLine.arguments[2]

let envFilePath = URL(fileURLWithPath: envFilePathString, isDirectory: false)
let exportFilePath = URL(fileURLWithPath: exportFilePathString, isDirectory: false)

let envFileContent = try String(contentsOf: envFilePath)

let lines = envFileContent.split(whereSeparator: \.isNewline)

var envValues: [String: String] = [:]

for line in lines {
  let values = line.split(separator: "=")
  let key = String(values[0])
  let value = String(values[1])
  envValues[key] = value
}

let cipher: [UInt8] = (0..<64).map { _ in
  UInt8.random(in: UInt8.min...UInt8.max)
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

func privateKeyVariableKey(key: String, value: String) -> some DeclSyntaxProtocol {
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

let source = SourceFileSyntax {
  for name in ["Algorithms", "Foundation"] {
    ImportDeclSyntax(path: AccessPathSyntax([AccessPathComponentSyntax(name: name)]))
  }
  
  EnumDeclSyntax(
    modifiers: [DeclModifierSyntax(name: .public)],
    identifier: "Env"
  ) {
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
    
    for (key, value) in envValues {
      privateKeyVariableKey(key: key, value: value)
    }
    
    for item in envValues {
      publicKeyVariableKey(key: item.key)
    }
    
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
}

let fileData = Data(source.formatted().description.utf8)

try fileData.write(to: exportFilePath)
