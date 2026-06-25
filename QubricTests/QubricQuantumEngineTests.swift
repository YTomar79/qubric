//
//  QubricQuantumEngineTests.swift
//  QubricTests
//
//  Unit tests for the state-vector simulator: complex arithmetic,
//  state resolution, gate application, and derived measurements.
//

import XCTest
@testable import Qubric

final class QubricQuantumEngineTests: XCTestCase {

    private let rootHalf = 1 / 2.0.squareRoot()
    private let tolerance = 1e-9

    // MARK: - Complex arithmetic

    func testComplexAddition() {
        let sum = Complex(re: 1, im: 2) + Complex(re: 3, im: -5)
        XCTAssertEqual(sum.re, 4, accuracy: tolerance)
        XCTAssertEqual(sum.im, -3, accuracy: tolerance)
    }

    func testComplexMultiplication() {
        // (1 + 2i)(3 + 4i) = -5 + 10i
        let product = Complex(re: 1, im: 2) * Complex(re: 3, im: 4)
        XCTAssertEqual(product.re, -5, accuracy: tolerance)
        XCTAssertEqual(product.im, 10, accuracy: tolerance)
    }

    func testComplexConjugateAndMagnitude() {
        let value = Complex(re: 3, im: 4)
        XCTAssertEqual(value.conjugate.im, -4, accuracy: tolerance)
        XCTAssertEqual(value.magnitudeSquared, 25, accuracy: tolerance)
    }

    func testComplexScaled() {
        let scaled = Complex(re: 1, im: -2).scaled(2)
        XCTAssertEqual(scaled.re, 2, accuracy: tolerance)
        XCTAssertEqual(scaled.im, -4, accuracy: tolerance)
    }

    // MARK: - State resolution

    func testResolveBellPhiPlus() throws {
        let state = try QubricQuantumEngine.resolveState("BELL_PHI_PLUS")
        XCTAssertEqual(state.count, 4)
        XCTAssertEqual(state[0].re, rootHalf, accuracy: tolerance)
        XCTAssertEqual(state[3].re, rootHalf, accuracy: tolerance)
        XCTAssertEqual(state[1].magnitudeSquared, 0, accuracy: tolerance)
        XCTAssertEqual(state[2].magnitudeSquared, 0, accuracy: tolerance)
    }

    func testResolveKetBasisState() throws {
        // |01> is the index-1 basis vector of a two-qubit register.
        let state = try QubricQuantumEngine.resolveState("|01>")
        XCTAssertEqual(state.count, 4)
        XCTAssertEqual(state[1].re, 1, accuracy: tolerance)
        XCTAssertEqual(state[0].magnitudeSquared + state[2].magnitudeSquared + state[3].magnitudeSquared,
                       0, accuracy: tolerance)
    }

    func testResolveSuperpositionKet() throws {
        let state = try QubricQuantumEngine.resolveState("|+>")
        XCTAssertEqual(state.count, 2)
        XCTAssertEqual(state[0].re, rootHalf, accuracy: tolerance)
        XCTAssertEqual(state[1].re, rootHalf, accuracy: tolerance)
    }

    func testResolveUnknownStateThrows() {
        XCTAssertThrowsError(try QubricQuantumEngine.resolveState("not-a-state"))
    }

    // MARK: - Single-qubit gates

    func testHadamardCreatesSuperposition() throws {
        let result = try QubricQuantumEngine.apply(gate: "H", to: [Complex(re: 1), .zero])
        XCTAssertEqual(result[0].re, rootHalf, accuracy: tolerance)
        XCTAssertEqual(result[1].re, rootHalf, accuracy: tolerance)
    }

    func testPauliXFlipsBasisState() throws {
        let result = try QubricQuantumEngine.apply(gate: "X", to: [Complex(re: 1), .zero])
        XCTAssertTrue(QubricQuantumEngine.statesEquivalent(result, [.zero, Complex(re: 1)]))
    }

    func testPauliZPhaseFlip() throws {
        let result = try QubricQuantumEngine.apply(gate: "Z", to: [.zero, Complex(re: 1)])
        XCTAssertEqual(result[1].re, -1, accuracy: tolerance)
    }

    func testUnsupportedGateThrows() {
        XCTAssertThrowsError(try QubricQuantumEngine.apply(gate: "Q", to: [Complex(re: 1), .zero]))
    }

    // MARK: - Two-qubit gates

    func testCNOTFlipsTargetWhenControlSet() throws {
        let input = try QubricQuantumEngine.resolveState("|10>")
        let result = try QubricQuantumEngine.apply(gate: "CNOT", to: input)
        let expected = try QubricQuantumEngine.resolveState("|11>")
        XCTAssertTrue(QubricQuantumEngine.statesEquivalent(result, expected))
    }

    func testHadamardThenCNOTProducesBellState() throws {
        var state = try QubricQuantumEngine.resolveState("|00>")
        state = try QubricQuantumEngine.apply(gate: "H0", to: state)
        state = try QubricQuantumEngine.apply(gate: "CNOT", to: state)
        let bell = try QubricQuantumEngine.resolveState("BELL_PHI_PLUS")
        XCTAssertTrue(QubricQuantumEngine.statesEquivalent(state, bell))
    }

    // MARK: - Derived quantities

    func testProbabilitiesSumOverBellState() throws {
        let bell = try QubricQuantumEngine.resolveState("BELL_PHI_PLUS")
        let probabilities = QubricQuantumEngine.probabilities(for: bell)
        XCTAssertEqual(probabilities.count, 4)
        XCTAssertEqual(probabilities[0].value, 50, accuracy: 0.1)
        XCTAssertEqual(probabilities[3].value, 50, accuracy: 0.1)
        XCTAssertEqual(probabilities[0].label, "00")
    }

    func testStatesEquivalentRejectsDifferentStates() {
        XCTAssertFalse(
            QubricQuantumEngine.statesEquivalent([Complex(re: 1), .zero], [.zero, Complex(re: 1)])
        )
    }

    func testGateSequenceKeyJoinsGates() {
        XCTAssertEqual(QubricQuantumEngine.gateSequenceKey(["H0", "CNOT"]), "H0,CNOT")
    }

    func testFormatBasisState() throws {
        let state = try QubricQuantumEngine.resolveState("|00>")
        XCTAssertEqual(QubricQuantumEngine.format(state), "|00>")
    }
}
