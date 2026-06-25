//
//  QubricQuantumEngine.swift
//  Qubric
//
//  Core simulation engine used to evaluate puzzle state.
//

import Foundation

struct Complex: Equatable, Hashable {
    var re: Double
    var im: Double = 0

    static let zero = Complex(re: 0)

    static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(re: lhs.re + rhs.re, im: lhs.im + rhs.im)
    }

    static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            re: lhs.re * rhs.re - lhs.im * rhs.im,
            im: lhs.re * rhs.im + lhs.im * rhs.re
        )
    }

    func scaled(_ value: Double) -> Complex {
        Complex(re: re * value, im: im * value)
    }

    var conjugate: Complex {
        Complex(re: re, im: -im)
    }

    var magnitudeSquared: Double {
        re * re + im * im
    }
}

struct SolveValidation {
    var state: [Complex]
    var gateCount: Int
    var hintsUsed: Int
    var probabilities: [ProbabilityEntry]
}

enum QubricQuantumError: LocalizedError {
    case unknownState(String)
    case unavailableGate(String)
    case unsupportedGate(String)
    case invalidState
    case overBudget(Int)
    case underMinimum(Int)
    case unsolved

    var errorDescription: String? {
        switch self {
        case .unknownState(let state): return "Unknown state \(state)."
        case .unavailableGate(let gate): return "\(gate) is not available in this puzzle."
        case .unsupportedGate(let gate): return "\(gate) is not supported."
        case .invalidState: return "Quantum state is invalid."
        case .overBudget(let max): return "Move limit reached. Use \(max) gates or fewer."
        case .underMinimum(let min): return "Use at least \(min) gates for this puzzle."
        case .unsolved: return "State does not match the goal."
        }
    }
}

enum QubricQuantumEngine {
    static let epsilon = 0.000001
    static let rootHalf = 1 / sqrt(2.0)

    static func resolveState(_ key: String) throws -> [Complex] {
        switch key {
        case "BELL_PHI_PLUS": return [Complex(re: rootHalf), .zero, .zero, Complex(re: rootHalf)]
        case "BELL_PHI_MINUS": return [Complex(re: rootHalf), .zero, .zero, Complex(re: -rootHalf)]
        case "BELL_PSI_PLUS": return [.zero, Complex(re: rootHalf), Complex(re: rootHalf), .zero]
        case "BELL_PSI_MINUS": return [.zero, Complex(re: rootHalf), Complex(re: -rootHalf), .zero]
        case "GHZ_PLUS": return [Complex(re: rootHalf), .zero, .zero, .zero, .zero, .zero, .zero, Complex(re: rootHalf)]
        case "GHZ_MINUS": return [Complex(re: rootHalf), .zero, .zero, .zero, .zero, .zero, .zero, Complex(re: -rootHalf)]
        default: return try parseKetState(key)
        }
    }

    private static func parseKetState(_ key: String) throws -> [Complex] {
        guard key.hasPrefix("|"), key.hasSuffix(">") else {
            throw QubricQuantumError.unknownState(key)
        }

        let body = String(key.dropFirst().dropLast())
        guard !body.isEmpty else { throw QubricQuantumError.unknownState(key) }

        var state = [Complex(re: 1)]
        for symbol in body {
            let factor: [Complex]
            switch symbol {
            case "0": factor = [Complex(re: 1), .zero]
            case "1": factor = [.zero, Complex(re: 1)]
            case "+": factor = [Complex(re: rootHalf), Complex(re: rootHalf)]
            case "-": factor = [Complex(re: rootHalf), Complex(re: -rootHalf)]
            default: throw QubricQuantumError.unknownState(key)
            }
            state = tensor(state, factor)
        }
        return state
    }

    private static func tensor(_ left: [Complex], _ right: [Complex]) -> [Complex] {
        left.flatMap { leftAmp in right.map { leftAmp * $0 } }
    }

    static func runCircuit(_ puzzle: QuantumPuzzle, gates: [String]) throws -> [Complex] {
        var state = try resolveState(puzzle.initialState)
        let allowed = expandedAvailableGates(for: puzzle)

        for gate in gates {
            guard allowed.contains(gate) else { throw QubricQuantumError.unavailableGate(gate) }
            state = try apply(gate: gate, to: state)
        }

        return state
    }

    static func expandedAvailableGates(for puzzle: QuantumPuzzle) -> Set<String> {
        let targeted = Set(["H", "X", "Y", "Z", "S"])
        let paired = Set(["CNOT", "CZ", "CP", "SWAP"])
        var allowed = Set<String>()

        for gate in puzzle.availableGates {
            if targeted.contains(gate), let targets = puzzle.targetQubits[gate], !targets.isEmpty {
                for target in targets {
                    allowed.insert("\(gate)\(target)")
                }
            } else if paired.contains(gate), let pairs = puzzle.targetPairs[gate], !pairs.isEmpty {
                for pair in pairs where pair.count == 2 {
                    allowed.insert("\(gate == "CP" ? "CZ" : gate)\(pair[0])\(pair[1])")
                }
            } else {
                allowed.insert(gate)
            }
        }

        return allowed
    }

    static func validate(_ puzzle: QuantumPuzzle, gates: [String], hintsUsed: Int) throws -> SolveValidation {
        if puzzle.puzzleType == "spot-difference" {
            guard gates.isEmpty else {
                throw QubricQuantumError.unsolved
            }
            let state = try resolveState(puzzle.goalState)
            return SolveValidation(
                state: state,
                gateCount: 0,
                hintsUsed: max(0, hintsUsed),
                probabilities: probabilities(for: state)
            )
        }

        guard !puzzle.strictBudget || gates.count <= puzzle.maxGates else {
            throw QubricQuantumError.overBudget(puzzle.maxGates)
        }
        guard gates.count >= puzzle.minGates else {
            throw QubricQuantumError.underMinimum(puzzle.minGates)
        }

        let state = try runCircuit(puzzle, gates: gates)
        guard try stateMatchesGoal(puzzle, state: state) else {
            throw QubricQuantumError.unsolved
        }
        guard matchesRequiredSolutionOrder(puzzle, gates: gates) else {
            throw QubricQuantumError.unsolved
        }

        return SolveValidation(
            state: state,
            gateCount: gates.count,
            hintsUsed: max(0, hintsUsed),
            probabilities: probabilities(for: state)
        )
    }

    static func score(_ puzzle: QuantumPuzzle, gates: [String], hintsUsed: Int, previousStats: SolveStats?, cleanSolver: Bool = false) -> (earned: Int, quality: SolveStats, breakdown: ScoreBreakdown) {
        let gateCount = gates.count
        let hintCount = max(0, hintsUsed)
        let overOptimal = max(0, gateCount - puzzle.optimalGates)
        let optimalBonus = gateCount <= puzzle.optimalGates ? 40 : max(0, 20 - overOptimal * 10)
        let noHintBonus = hintCount == 0 ? 30 : 0
        let hintSpend = hintCount * puzzle.hintCost
        let overOptimalPenalty = overOptimal * 10
        let multiplier = cleanSolver ? 1.5 : 1.0
        let baseScore = max(0, puzzle.xp + optimalBonus + noHintBonus - overOptimalPenalty - hintSpend)
        let cleanSolverBonus = Int((Double(baseScore) * multiplier).rounded()) - baseScore
        let bestScore = baseScore + cleanSolverBonus
        let previousBest = previousStats?.bestScore ?? 0
        let improved = bestScore > previousBest
        let alreadySolved = (previousStats?.attempts ?? 0) > 0
        let earned = alreadySolved ? (improved ? max(20, Int((Double(bestScore) * 0.18).rounded())) : 10) : bestScore
        let perfect = gateCount <= puzzle.optimalGates && hintCount == 0

        let bestGateCount: Int
        if let previous = previousStats?.bestGateCount {
            bestGateCount = min(previous, gateCount)
        } else {
            bestGateCount = gateCount
        }

        let hintsUsedBest: Int
        if improved || previousStats?.hintsUsedBest == nil {
            hintsUsedBest = hintCount
        } else {
            hintsUsedBest = min(previousStats?.hintsUsedBest ?? hintCount, hintCount)
        }

        return (
            earned,
            SolveStats(
                attempts: (previousStats?.attempts ?? 0) + 1,
                bestGateCount: bestGateCount,
                bestScore: max(previousBest, bestScore),
                hintsUsedBest: hintsUsedBest,
                perfect: (previousStats?.perfect ?? false) || perfect,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ),
            ScoreBreakdown(
                baseXp: puzzle.xp,
                optimalBonus: optimalBonus,
                noHintBonus: noHintBonus,
                overOptimalPenalty: overOptimalPenalty,
                hintPenalty: hintSpend,
                cleanSolverMultiplier: multiplier,
                cleanSolverBonus: cleanSolverBonus,
                bestScore: bestScore,
                replayReward: alreadySolved,
                improvedReplay: alreadySolved && improved,
                earned: earned,
                dailyBonus: nil
            )
        )
    }

    static func apply(gate: String, to state: [Complex]) throws -> [Complex] {
        guard let qubits = qubitCount(for: state) else {
            throw QubricQuantumError.invalidState
        }

        if let single = parseSingleGate(gate: gate, qubits: qubits) {
            return applySingleGate(state: state, qubits: qubits, name: single.name, target: single.target)
        }

        if let pair = parsePairGate(gate: gate, qubits: qubits) {
            switch pair.name {
            case "CNOT": return try applyCNOT(state: state, qubits: qubits, control: pair.first, target: pair.second)
            case "SWAP": return try applySwap(state: state, qubits: qubits, first: pair.first, second: pair.second)
            case "CZ": return try applyControlledPhase(state: state, qubits: qubits, first: pair.first, second: pair.second)
            default: break
            }
        }

        throw QubricQuantumError.unsupportedGate(gate)
    }

    static func stateMatchesGoal(_ puzzle: QuantumPuzzle, state: [Complex]) throws -> Bool {
        let goal = try resolveState(puzzle.goalState)
        guard goal.count == state.count else { return false }
        return fidelity(goal, state) >= 1 - epsilon
    }

    static func statesEquivalent(_ left: [Complex], _ right: [Complex]) -> Bool {
        guard left.count == right.count else { return false }
        return fidelity(left, right) >= 1 - epsilon
    }

    static func gateSequenceKey(_ gates: [String]) -> String {
        gates.joined(separator: ",")
    }

    private static func allowedSolutionRoutes(_ puzzle: QuantumPuzzle) -> [[String]] {
        let alternates = puzzle.alternateSolutionMessages.keys.map { key in
            key.split(separator: ",").map(String.init)
        }
        return [puzzle.solutionGates] + alternates
    }

    static func startsAllowedSolutionRoute(_ puzzle: QuantumPuzzle, gates: [String]) -> Bool {
        allowedSolutionRoutes(puzzle).contains { route in
            gates.count <= route.count && zip(gates, route).allSatisfy { $0 == $1 }
        }
    }

    static func matchesRequiredSolutionOrder(_ puzzle: QuantumPuzzle, gates: [String]) -> Bool {
        if !puzzle.enforceSolutionOrder { return true }
        return allowedSolutionRoutes(puzzle).contains { route in
            gates.count == route.count && zip(gates, route).allSatisfy { $0 == $1 }
        }
    }

    static func probabilities(for state: [Complex]) -> [ProbabilityEntry] {
        guard let qubits = qubitCount(for: state) else { return [] }
        return state.enumerated().map { index, amp in
            ProbabilityEntry(
                label: String(index, radix: 2).leftPadded(to: qubits, with: "0"),
                value: (amp.magnitudeSquared * 1000).rounded() / 10
            )
        }
    }

    static func probabilityShapeMatches(_ left: [Complex], _ right: [Complex]) -> Bool {
        guard left.count == right.count else { return false }
        return zip(left, right).allSatisfy { pair in
            abs(pair.0.magnitudeSquared - pair.1.magnitudeSquared) <= 0.015
        }
    }

    static func signShapeMatches(_ left: [Complex], _ right: [Complex]) -> Bool {
        guard probabilityShapeMatches(left, right) else { return false }
        guard let pivot = left.indices.first(where: { phaseSign(left[$0]) != 0 && phaseSign(right[$0]) != 0 }) else {
            return true
        }
        let globalSign = phaseSign(left[pivot]) == phaseSign(right[pivot]) ? 1 : -1
        return left.indices.allSatisfy { index in
            let leftSign = phaseSign(left[index])
            let rightSign = phaseSign(right[index])
            return leftSign == 0 || rightSign == 0 || leftSign == rightSign * globalSign
        }
    }

    static func format(_ state: [Complex]) -> String {
        guard let qubits = qubitCount(for: state) else { return "0" }
        let terms = state.enumerated().filter { $0.element.magnitudeSquared > epsilon }
        guard !terms.isEmpty else { return "0" }

        return terms.enumerated().reduce("") { text, item in
            let isFirst = item.offset == 0
            let index = item.element.offset
            let amp = item.element.element
            let raw = formatAmplitude(amp)
            let negative = raw.hasPrefix("-")
            let clean = negative ? String(raw.dropFirst()) : raw
            let label = String(index, radix: 2).leftPadded(to: qubits, with: "0")
            let rendered = clean == "1" ? "|\(label)>" : "\(clean)|\(label)>"

            if isFirst {
                return negative ? "-\(rendered)" : rendered
            }
            return "\(text) \(negative ? "-" : "+") \(rendered)"
        }
    }

    private static func qubitCount(for state: [Complex]) -> Int? {
        guard state.count > 0 else { return nil }

        let qubits = Int(round(log2(Double(state.count))))
        guard qubits >= 0, (1 << qubits) == state.count else { return nil }
        return qubits
    }

    private static func phaseSign(_ amplitude: Complex) -> Int {
        guard sqrt(amplitude.magnitudeSquared) > epsilon else { return 0 }
        if abs(amplitude.im) > abs(amplitude.re) {
            return amplitude.im < -epsilon ? -1 : 1
        }
        return amplitude.re < -epsilon ? -1 : 1
    }

    private static func parseSingleGate(gate: String, qubits: Int) -> (name: Character, target: Int)? {
        let singleGateNames = Set<Character>(["H", "X", "Y", "Z", "S"])
        guard let first = gate.first, singleGateNames.contains(first) else { return nil }
        let suffix = gate.dropFirst()
        let target = suffix.isEmpty ? 0 : Int(suffix) ?? -1
        guard target >= 0 && target < qubits else { return nil }
        return (first, target)
    }

    private static func parsePairGate(gate: String, qubits: Int) -> (name: String, first: Int, second: Int)? {
        if gate == "CNOT" { return ("CNOT", 0, 1) }
        if gate == "SWAP" { return ("SWAP", 0, 1) }
        if gate == "CZ" || gate == "CP" { return ("CZ", 0, 1) }

        for rawName in ["CNOT", "SWAP", "CZ", "CP"] {
            guard gate.hasPrefix(rawName) else { continue }
            let suffix = String(gate.dropFirst(rawName.count))
            guard suffix.count == 2 else { return nil }
            let values = suffix.compactMap { Int(String($0)) }
            guard values.count == 2 else { return nil }
            let first = values[0]
            let second = values[1]
            guard first != second, first >= 0, second >= 0, first < qubits, second < qubits else {
                return nil
            }
            return (rawName == "CP" ? "CZ" : rawName, first, second)
        }

        return nil
    }

    private static func matrix(for name: Character) -> [[Complex]] {
        switch name {
        case "H":
            return [
                [Complex(re: rootHalf), Complex(re: rootHalf)],
                [Complex(re: rootHalf), Complex(re: -rootHalf)]
            ]
        case "X":
            return [[.zero, Complex(re: 1)], [Complex(re: 1), .zero]]
        case "Y":
            return [[.zero, Complex(re: 0, im: -1)], [Complex(re: 0, im: 1), .zero]]
        case "Z":
            return [[Complex(re: 1), .zero], [.zero, Complex(re: -1)]]
        case "S":
            return [[Complex(re: 1), .zero], [.zero, Complex(re: 0, im: 1)]]
        default:
            return [[Complex(re: 1), .zero], [.zero, Complex(re: 1)]]
        }
    }

    private static func applySingleGate(state: [Complex], qubits: Int, name: Character, target: Int) -> [Complex] {
        let matrix = matrix(for: name)
        let mask = bitMask(qubits: qubits, target: target)
        var next = Array(repeating: Complex.zero, count: state.count)

        for (index, amp) in state.enumerated() {
            let inputBit = (index & mask) == 0 ? 0 : 1
            for outputBit in 0...1 {
                let outputIndex = outputBit == inputBit ? index : index ^ mask
                next[outputIndex] = next[outputIndex] + matrix[outputBit][inputBit] * amp
            }
        }

        return normalize(next)
    }

    private static func applyCNOT(state: [Complex], qubits: Int, control: Int, target: Int) throws -> [Complex] {
        guard control != target, control >= 0, target >= 0, control < qubits, target < qubits else {
            throw QubricQuantumError.unsupportedGate("CNOT")
        }
        let controlMask = bitMask(qubits: qubits, target: control)
        let targetMask = bitMask(qubits: qubits, target: target)
        var next = Array(repeating: Complex.zero, count: state.count)

        for (index, amp) in state.enumerated() {
            let outputIndex = (index & controlMask) == 0 ? index : index ^ targetMask
            next[outputIndex] = next[outputIndex] + amp
        }

        return normalize(next)
    }

    private static func applySwap(state: [Complex], qubits: Int, first: Int, second: Int) throws -> [Complex] {
        guard first != second, first >= 0, second >= 0, first < qubits, second < qubits else {
            throw QubricQuantumError.unsupportedGate("SWAP")
        }
        let firstMask = bitMask(qubits: qubits, target: first)
        let secondMask = bitMask(qubits: qubits, target: second)
        var next = Array(repeating: Complex.zero, count: state.count)

        for (index, amp) in state.enumerated() {
            let firstBit = (index & firstMask) == 0 ? 0 : 1
            let secondBit = (index & secondMask) == 0 ? 0 : 1
            let outputIndex = firstBit == secondBit ? index : index ^ firstMask ^ secondMask
            next[outputIndex] = amp
        }

        return next
    }

    private static func applyControlledPhase(state: [Complex], qubits: Int, first: Int, second: Int) throws -> [Complex] {
        guard first != second, first >= 0, second >= 0, first < qubits, second < qubits else {
            throw QubricQuantumError.unsupportedGate("CZ")
        }
        let firstMask = bitMask(qubits: qubits, target: first)
        let secondMask = bitMask(qubits: qubits, target: second)
        var next = state
        for index in next.indices where (index & firstMask) != 0 && (index & secondMask) != 0 {
            next[index] = next[index].scaled(-1)
        }
        return normalize(next)
    }

    private static func bitMask(qubits: Int, target: Int) -> Int {
        1 << (qubits - 1 - target)
    }

    private static func normalize(_ state: [Complex]) -> [Complex] {
        let norm = sqrt(state.reduce(0) { $0 + $1.magnitudeSquared })
        guard norm > epsilon else { return state }
        return state.map { $0.scaled(1 / norm) }
    }

    private static func innerProduct(_ lhs: [Complex], _ rhs: [Complex]) -> Complex {
        lhs.enumerated().reduce(.zero) { total, item in
            total + item.element.conjugate * rhs[item.offset]
        }
    }

    private static func fidelity(_ lhs: [Complex], _ rhs: [Complex]) -> Double {
        let inner = innerProduct(normalize(lhs), normalize(rhs))
        return inner.magnitudeSquared
    }

    private static func nearly(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) <= epsilon
    }

    private static func number(_ value: Double) -> String {
        if nearly(value, rootHalf) { return "1/√2" }
        if nearly(value, -rootHalf) { return "-1/√2" }
        if nearly(value, 1) { return "1" }
        if nearly(value, -1) { return "-1" }
        return String(format: "%.2f", value).replacingOccurrences(of: #"(\.?0+)$"#, with: "", options: .regularExpression)
    }

    private static func formatAmplitude(_ amp: Complex) -> String {
        let re = nearly(amp.re, 0) ? 0 : amp.re
        let im = nearly(amp.im, 0) ? 0 : amp.im

        if im == 0 { return number(re) }
        if re == 0 {
            if nearly(im, rootHalf) { return "i/√2" }
            if nearly(im, -rootHalf) { return "-i/√2" }
            if nearly(im, 1) { return "i" }
            if nearly(im, -1) { return "-i" }
            return "\(number(im))i"
        }

        return "(\(number(re)) \(im > 0 ? "+" : "-") \(number(abs(im)))i)"
    }
}

private extension String {
    func leftPadded(to count: Int, with character: Character) -> String {
        if self.count >= count { return self }
        return String(repeating: String(character), count: count - self.count) + self
    }
}
