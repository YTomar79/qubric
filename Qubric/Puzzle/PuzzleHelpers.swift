//
//  PuzzleHelpers.swift
//  Qubric
//
//  Shared helpers for the puzzle module.
//

import Foundation

struct GateEffect: Equatable {
    let gate: String
    let id: Int
    var noOp = false

    var base: String {
        gate.replacingOccurrences(of: #"\d+$"#, with: "", options: .regularExpression)
    }
}
