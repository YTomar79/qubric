//
//  QubricModels.swift
//  Qubric
//
//  Core data models and shared value types.
//

import Foundation

struct PredictionOption: Identifiable, Hashable, Codable {
    let id: String
    let label: String
}

struct PuzzlePrediction: Hashable, Codable {
    let prompt: String
    let options: [PredictionOption]
    let correctOptionId: String
    let explanation: String
}

struct QubitLabel: Identifiable, Hashable, Codable {
    var id: Int { index }
    let index: Int
    let short: String
    let detail: String
}

struct PuzzleSpotDifference: Hashable, Codable {
    let prompt: String
    let state: String
    let basis: String
    let phase: String
    let success: String
    let miss: String
}

struct PuzzleStageCheckpoint: Hashable, Codable {
    let move: Int
    let state: String
    let label: String
}

struct QuantumPuzzle: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let xp: Int
    let difficulty: String
    let puzzleType: String
    let objective: String
    let concept: String
    let initialState: String
    let goalState: String
    let availableGates: [String]
    let solutionGates: [String]
    let targetQubits: [String: [Int]]
    let targetPairs: [String: [[Int]]]
    let maxGates: Int
    let minGates: Int
    let optimalGates: Int
    let hintCost: Int
    let hints: [String]
    let recap: String
    let chapterNumber: Int
    let hintTiers: [String]
    let teaches: [String]
    let strictBudget: Bool
    let showMoveTarget: Bool
    let showNotation: Bool
    let showProbabilities: Bool
    let showPhase: Bool
    let showGateLabels: Bool
    let showMoveDiff: Bool
    let explicitTargetButtons: Bool
    let solvedMessage: String?
    let stageFeedback: [String]
    let spotDifference: PuzzleSpotDifference?
    let beforeMovePrompt: String?
    let firstMovePrompt: String?
    let activePrompt: String?
    let practiceLabel: String?
    let prediction: PuzzlePrediction?
    let reflection: PuzzlePrediction?
    let qubitLabels: [QubitLabel]
    let wrongGateFeedback: [String: String]
    let postSolvePrompt: String?
    let alternateSolutionMessages: [String: String]
    let enforceSolutionOrder: Bool
    let stageCheckpoints: [PuzzleStageCheckpoint]
    let stageLabels: [String]

    var gates: [String] { availableGates }

    func qubitLabel(for index: Int) -> QubitLabel {
        qubitLabels.first { $0.index == index }
            ?? QubitLabel(index: index, short: "q\(index)", detail: index == 0 ? "left bit" : index == 1 ? "right bit" : "bit \(index)")
    }

    init(
        id: String,
        title: String,
        xp: Int,
        difficulty: String,
        puzzleType: String,
        objective: String,
        concept: String,
        initialState: String,
        goalState: String,
        availableGates: [String],
        solutionGates: [String] = [],
        targetQubits: [String: [Int]] = [:],
        targetPairs: [String: [[Int]]] = [:],
        maxGates: Int,
        minGates: Int = 0,
        optimalGates: Int,
        hintCost: Int,
        hints: [String],
        recap: String,
        chapterNumber: Int,
        hintTiers: [String]? = nil,
        teaches: [String] = [],
        strictBudget: Bool = true,
        showMoveTarget: Bool = true,
        showNotation: Bool = true,
        showProbabilities: Bool = true,
        showPhase: Bool? = nil,
        showGateLabels: Bool = false,
        showMoveDiff: Bool = true,
        explicitTargetButtons: Bool = false,
        solvedMessage: String? = nil,
        stageFeedback: [String] = [],
        spotDifference: PuzzleSpotDifference? = nil,
        beforeMovePrompt: String? = nil,
        firstMovePrompt: String? = nil,
        activePrompt: String? = nil,
        practiceLabel: String? = nil,
        prediction: PuzzlePrediction? = nil,
        reflection: PuzzlePrediction? = nil,
        qubitLabels: [QubitLabel] = [],
        wrongGateFeedback: [String: String] = [:],
        postSolvePrompt: String? = nil,
        alternateSolutionMessages: [String: String] = [:],
        enforceSolutionOrder: Bool = false,
        stageCheckpoints: [PuzzleStageCheckpoint] = [],
        stageLabels: [String] = []
    ) {
        self.id = id
        self.title = title
        self.xp = xp
        self.difficulty = difficulty
        self.puzzleType = puzzleType
        self.objective = objective
        self.concept = concept
        self.initialState = initialState
        self.goalState = goalState
        self.availableGates = availableGates
        self.solutionGates = solutionGates
        self.targetQubits = targetQubits
        self.targetPairs = targetPairs
        self.maxGates = maxGates
        self.minGates = minGates
        self.optimalGates = optimalGates
        self.hintCost = hintCost
        self.hintTiers = hintTiers ?? hints
        self.hints = hintTiers ?? hints
        self.recap = recap
        self.chapterNumber = chapterNumber
        self.teaches = teaches
        self.strictBudget = strictBudget
        self.showMoveTarget = showMoveTarget
        self.showNotation = showNotation
        self.showProbabilities = showProbabilities
        self.showPhase = showPhase ?? showNotation
        self.showGateLabels = showGateLabels
        self.showMoveDiff = showMoveDiff
        self.explicitTargetButtons = explicitTargetButtons
        self.solvedMessage = solvedMessage
        self.stageFeedback = stageFeedback
        self.spotDifference = spotDifference
        self.beforeMovePrompt = beforeMovePrompt
        self.firstMovePrompt = firstMovePrompt
        self.activePrompt = activePrompt
        self.practiceLabel = practiceLabel
        self.prediction = prediction
        self.reflection = reflection
        self.qubitLabels = qubitLabels
        self.wrongGateFeedback = wrongGateFeedback
        self.postSolvePrompt = postSolvePrompt
        self.alternateSolutionMessages = alternateSolutionMessages
        self.enforceSolutionOrder = enforceSolutionOrder
        self.stageCheckpoints = stageCheckpoints
        self.stageLabels = stageLabels
    }
}

struct ProbabilityEntry: Identifiable, Hashable, Codable {
    var id: String { label }
    let label: String
    let value: Double
}

struct SolveStats: Codable, Equatable, Hashable {
    var attempts: Int = 0
    var bestGateCount: Int?
    var bestScore: Int = 0
    var hintsUsedBest: Int?
    var perfect: Bool = false
    var reflectionAnswered: Bool = false
    var reflectionCorrect: Bool = false
    var reflectionAnsweredAt: String?
    var updatedAt: String = ISO8601DateFormatter().string(from: Date())

    enum CodingKeys: String, CodingKey {
        case attempts
        case bestGateCount
        case bestScore
        case hintsUsedBest
        case perfect
        case reflectionAnswered
        case reflectionCorrect
        case reflectionAnsweredAt
        case updatedAt
    }

    init(
        attempts: Int = 0,
        bestGateCount: Int? = nil,
        bestScore: Int = 0,
        hintsUsedBest: Int? = nil,
        perfect: Bool = false,
        reflectionAnswered: Bool = false,
        reflectionCorrect: Bool = false,
        reflectionAnsweredAt: String? = nil,
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.attempts = attempts
        self.bestGateCount = bestGateCount
        self.bestScore = bestScore
        self.hintsUsedBest = hintsUsedBest
        self.perfect = perfect
        self.reflectionAnswered = reflectionAnswered
        self.reflectionCorrect = reflectionCorrect
        self.reflectionAnsweredAt = reflectionAnsweredAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attempts = try container.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        bestGateCount = try container.decodeIfPresent(Int.self, forKey: .bestGateCount)
        bestScore = try container.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        hintsUsedBest = try container.decodeIfPresent(Int.self, forKey: .hintsUsedBest)
        perfect = try container.decodeIfPresent(Bool.self, forKey: .perfect) ?? false
        reflectionAnswered = try container.decodeIfPresent(Bool.self, forKey: .reflectionAnswered) ?? false
        reflectionCorrect = try container.decodeIfPresent(Bool.self, forKey: .reflectionCorrect) ?? false
        reflectionAnsweredAt = try container.decodeIfPresent(String.self, forKey: .reflectionAnsweredAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ISO8601DateFormatter().string(from: Date())
    }
}

struct PlayerSettings: Codable, Equatable, Hashable {
    var skipReflections: Bool = false
    var hintsEnabled: Bool = true
    var showNotation: Bool = false
    var badgeNotificationsEnabled: Bool = false

    enum CodingKeys: String, CodingKey {
        case skipReflections
        case hintsEnabled
        case showNotation
        case badgeNotificationsEnabled
    }

    init(skipReflections: Bool = false, hintsEnabled: Bool = true, showNotation: Bool = false, badgeNotificationsEnabled: Bool = false) {
        self.skipReflections = skipReflections
        self.hintsEnabled = hintsEnabled
        self.showNotation = showNotation
        self.badgeNotificationsEnabled = badgeNotificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        skipReflections = try container.decodeIfPresent(Bool.self, forKey: .skipReflections) ?? false
        hintsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hintsEnabled) ?? true
        showNotation = try container.decodeIfPresent(Bool.self, forKey: .showNotation) ?? false
        badgeNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .badgeNotificationsEnabled) ?? false
    }
}

struct ProgressStreak: Codable, Equatable, Hashable {
    var current: Int = 0
    var longest: Int = 0
    var lastSolvedDay: String?
}

struct QubricChapter: Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let theme: String
    let summary: String
    let puzzles: [QuantumPuzzle]
}

struct QubricBadge: Identifiable, Hashable {
    let id: String
    let label: String
    let earned: Bool
    let progressLabel: String?
}

struct PlayerProfile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var avatarPresetId: String?
    var xp: Int = 0
    var completed: [String: Bool] = [:]
    var unlocked: [String: Bool] = [QubricData.firstPuzzleId: true]
    var dailyXp: [String: Int] = [QubricData.todayKey(): 0]
    var mistakes: Int = 0
    var sound: Bool = true
    var settings = PlayerSettings()
    var streak = ProgressStreak()
    var solveStats: [String: SolveStats] = [:]
    var createdAt: Date = Date()
    var lastSeenAt: Date = Date()
}

enum QubricData {
    // Generated from src/data/puzzleDefinitions.js. Run npm run generate:ios-puzzles after editing puzzle data.
    static let chapters: [QubricChapter] = [
        QubricChapter(
            id: "chapter-1",
            number: 1,
            title: "Foundations",
            theme: "Ordered single-bit proofs",
            summary: "Build split, flip, sign, and interference routes without one-tap guesses.",
            puzzles: [
                QuantumPuzzle(
                    id: "1.1",
                    title: "Split the Coin",
                    xp: 100,
                    difficulty: "Tutorial",
                    puzzleType: "reach-state",
                    objective: "Make 0 split into both outcomes.",
                    concept: "H is the split gate. It turns one certain outcome into two equal chances.",
                    initialState: "|0>",
                    goalState: "|+>",
                    availableGates: ["H"],
                    solutionGates: ["H"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 1,
                    minGates: 0,
                    optimalGates: 1,
                    hintCost: 20,
                    hints: ["The goal has two equal chance bars: 0 and 1 both need a chance.", "Use the gate whose job is to split one path into two.", "Use H."],
                    recap: "H changed certain 0 into an even 0/1 split.",
                    chapterNumber: 1,
                    hintTiers: ["The goal has two equal chance bars: 0 and 1 both need a chance.", "Use the gate whose job is to split one path into two.", "Use H."],
                    teaches: ["h-creates-even-split"],
                    strictBudget: false,
                    showMoveTarget: false,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: false,
                    showGateLabels: true,
                    showMoveDiff: false,
                    explicitTargetButtons: false,
                    solvedMessage: "One certain path became two equal paths.",
                    stageFeedback: ["The split is built."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: "Tap H.",
                    activePrompt: "Tap H.",
                    practiceLabel: "Guided demo. Real puzzles start at 1.2.",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: nil,
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: false,
                    stageCheckpoints: [],
                    stageLabels: ["Tap H to split the bar."]
                ),
                QuantumPuzzle(
                    id: "1.2",
                    title: "Close, Then Flip",
                    xp: 150,
                    difficulty: "Route 2",
                    puzzleType: "reach-state",
                    objective: "Close the split, then flip the result.",
                    concept: "A two-step route can use H to close a split before X moves the full bar.",
                    initialState: "|+>",
                    goalState: "|1>",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["H", "X"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 2,
                    minGates: 0,
                    optimalGates: 2,
                    hintCost: 20,
                    hints: ["Start by closing the split before you try to flip anything.", "After H makes a certain 0, X can move it to 1.", "Use H, then X."],
                    recap: "The route was H to close, then X to flip.",
                    chapterNumber: 1,
                    hintTiers: ["Start by closing the split before you try to flip anything.", "After H makes a certain 0, X can move it to 1.", "Use H, then X."],
                    teaches: ["h-can-undo-itself", "x-flips-bit", "ordered-routes"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: false,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You closed the split, then flipped it.",
                    stageFeedback: ["The split closed into 0. The route is not done.", "The flip lands on 1."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "2-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "That breaks the route. Reset and follow the prompts.", "X": "X first leaves |+> balanced. Close the split with H, then use X on the closed bar.", "Z": "Z changes a sign, but this route starts by closing the split with H."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|0>", label: "Split closed"),
                        PuzzleStageCheckpoint(move: 2, state: "|1>", label: "Flip complete")
                    ],
                    stageLabels: ["Close the split with H.", "Now flip the closed bar with X."]
                ),
                QuantumPuzzle(
                    id: "1.3",
                    title: "Hidden Flip Proof",
                    xp: 180,
                    difficulty: "Route 3",
                    puzzleType: "reach-state",
                    objective: "Turn 0 into 1 without taking the one-tap shortcut.",
                    concept: "H, Z, H is a proof route: split, mark one path, then let interference reveal 1.",
                    initialState: "|0>",
                    goalState: "|1>",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["H", "Z", "H"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 3,
                    minGates: 0,
                    optimalGates: 3,
                    hintCost: 20,
                    hints: ["This puzzle rejects the direct shortcut. Build the proof route.", "First split, then change the sign on one path.", "Use H, Z, H."],
                    recap: "A sign change between two H gates behaves like a flip.",
                    chapterNumber: 1,
                    hintTiers: ["This puzzle rejects the direct shortcut. Build the proof route.", "First split, then change the sign on one path.", "Use H, Z, H."],
                    teaches: ["phase-signs-are-state", "interference-reveals-signs"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You built X out of H, Z, H.",
                    stageFeedback: ["The split is ready for a sign mark.", "The sign is marked. Recombine it.", "The hidden sign revealed 1."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "3-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "H belongs at the start and end. If it breaks the prefix, reset and trace H, Z, H exactly.", "X": "X is the shortcut here. This route is testing whether you can build the H-Z-H interference proof.", "Z": "Z needs a split to mark. Start with H so the sign has a path to change."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|+>", label: "Split made"),
                        PuzzleStageCheckpoint(move: 2, state: "|->", label: "Sign marked"),
                        PuzzleStageCheckpoint(move: 3, state: "|1>", label: "Interference revealed")
                    ],
                    stageLabels: ["Split 0 with H.", "Mark the 1 path with Z.", "Use H again to reveal the mark as 1."]
                ),
                QuantumPuzzle(
                    id: "1.4",
                    title: "Quiet Middle Move",
                    xp: 210,
                    difficulty: "Route 4",
                    puzzleType: "reach-state",
                    objective: "Follow a four-move route and watch for a quiet gate.",
                    concept: "Some moves matter because of where they sit in the route. X on a balanced split does not move the bars.",
                    initialState: "|0>",
                    goalState: "|1>",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["H", "X", "Z", "H"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 4,
                    minGates: 0,
                    optimalGates: 4,
                    hintCost: 20,
                    hints: ["The second move is quiet: X does not move an even split.", "After the quiet X, Z marks the sign.", "Use H, X, Z, H."],
                    recap: "X can be quiet on an even split, so order matters.",
                    chapterNumber: 1,
                    hintTiers: ["The second move is quiet: X does not move an even split.", "After the quiet X, Z marks the sign.", "Use H, X, Z, H."],
                    teaches: ["noop-on-balanced-split", "ordered-routes"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "The quiet middle move stayed on route.",
                    stageFeedback: ["Split made.", "Bars did not move, but the route step is complete.", "Sign marked.", "Recombined into 1."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "4-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "That breaks the route. Reset and follow the prompts.", "X": "X is the second move here, not the opener. Split first so you can see the quiet move.", "Z": "Z before the split changes no visible bar. Start with H."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|+>", label: "Split made"),
                        PuzzleStageCheckpoint(move: 2, state: "|+>", label: "Quiet X"),
                        PuzzleStageCheckpoint(move: 3, state: "|->", label: "Sign marked"),
                        PuzzleStageCheckpoint(move: 4, state: "|1>", label: "Recombined")
                    ],
                    stageLabels: ["Split 0 with H.", "Apply X and watch the bars stay put.", "Now mark the sign with Z.", "Recombine with H."]
                ),
                QuantumPuzzle(
                    id: "1.5",
                    title: "Same Bars, New Sign",
                    xp: 160,
                    difficulty: "Spot",
                    puzzleType: "spot-difference",
                    objective: "Spot the sign difference between two equal bars.",
                    concept: "Two states can have the same chance bars and still differ by a path sign.",
                    initialState: "|+>",
                    goalState: "|->",
                    availableGates: [],
                    solutionGates: [],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 0,
                    minGates: 0,
                    optimalGates: 0,
                    hintCost: 20,
                    hints: ["The bars already match, so the difference is not probability.", "Look for the sign that changed.", "Tap the minus sign on the target 1 path."],
                    recap: "The bars can match while the path signs differ.",
                    chapterNumber: 1,
                    hintTiers: ["The bars already match, so the difference is not probability.", "Look for the sign that changed.", "Tap the minus sign on the target 1 path."],
                    teaches: ["phase-signs-are-state"],
                    strictBudget: false,
                    showMoveTarget: false,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: false,
                    showMoveDiff: false,
                    explicitTargetButtons: false,
                    solvedMessage: "You found the sign difference.",
                    stageFeedback: [],
                    spotDifference: PuzzleSpotDifference(
                        prompt: "Tap the minus sign on the target 1 path.",
                        state: "goal",
                        basis: "1",
                        phase: "-",
                        success: "Right: the bars match, but the 1 path has a different sign.",
                        miss: "Not that one. The chance bars match, so look only at the signs."
                    ),
                    beforeMovePrompt: nil,
                    firstMovePrompt: "Tap the sign that differs.",
                    activePrompt: "The bars match, so compare only the signs.",
                    practiceLabel: "Spot the sign.",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: [:],
                    postSolvePrompt: nil,
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: false,
                    stageCheckpoints: [],
                    stageLabels: []
                ),
                QuantumPuzzle(
                    id: "1.6",
                    title: "Flip the Sign Route",
                    xp: 250,
                    difficulty: "Route 5",
                    puzzleType: "reach-state",
                    objective: "Return to the same bars with the opposite sign.",
                    concept: "A sign route can reveal, reset, rebuild, and mark the split again.",
                    initialState: "|+>",
                    goalState: "|->",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["Z", "H", "X", "H", "Z"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 5,
                    minGates: 0,
                    optimalGates: 5,
                    hintCost: 20,
                    hints: ["Start by flipping the sign, then reveal what that sign does.", "After the reveal, reset the bar and rebuild the split.", "Use Z, H, X, H, Z."],
                    recap: "Z flips the sign; H reveals what the sign means.",
                    chapterNumber: 1,
                    hintTiers: ["Start by flipping the sign, then reveal what that sign does.", "After the reveal, reset the bar and rebuild the split.", "Use Z, H, X, H, Z."],
                    teaches: ["phase-drill", "interference-reveal"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You rebuilt the same bars with the opposite sign.",
                    stageFeedback: ["The sign flipped while the bars stayed balanced.", "The sign revealed itself as 1.", "The bar reset to 0.", "The split is back.", "The target sign is built."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "5-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "H reveals signs, but this route first needs Z to create the sign change.", "X": "X cannot change only the sign of a balanced split. Start with Z.", "Z": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|->", label: "Sign flipped"),
                        PuzzleStageCheckpoint(move: 2, state: "|1>", label: "Sign revealed"),
                        PuzzleStageCheckpoint(move: 3, state: "|0>", label: "Reset"),
                        PuzzleStageCheckpoint(move: 4, state: "|+>", label: "Split rebuilt"),
                        PuzzleStageCheckpoint(move: 5, state: "|->", label: "Sign target")
                    ],
                    stageLabels: ["Flip the sign with Z.", "Reveal the sign with H.", "Reset the full bar with X.", "Split again with H.", "Flip the sign once more with Z."]
                ),
                QuantumPuzzle(
                    id: "1.7",
                    title: "Reveal, Reset, Reveal",
                    xp: 280,
                    difficulty: "Route 6",
                    puzzleType: "reach-state",
                    objective: "Use the sign twice and finish on 1.",
                    concept: "The minus sign is not decoration. H can turn that sign into a certain outcome.",
                    initialState: "|->",
                    goalState: "|1>",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["H", "X", "H", "Z", "H", "Z"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 6,
                    minGates: 0,
                    optimalGates: 6,
                    hintCost: 20,
                    hints: ["Start by revealing the minus sign with H.", "Reset, rebuild the split, and mark it again.", "Use H, X, H, Z, H, Z."],
                    recap: "A sign can hide in the bars until H reveals it.",
                    chapterNumber: 1,
                    hintTiers: ["Start by revealing the minus sign with H.", "Reset, rebuild the split, and mark it again.", "Use H, X, H, Z, H, Z."],
                    teaches: ["interference-reveal", "global-phase-tolerance"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You used interference twice.",
                    stageFeedback: ["The sign revealed 1.", "Reset complete.", "Split rebuilt.", "Sign marked again.", "The mark revealed 1.", "Final sign mark complete."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "6-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "That breaks the route. Reset and follow the prompts.", "X": "X flips a full bar. The starting state is split, so reveal it with H first.", "Z": "Z flips signs, but the first move must reveal the existing sign with H."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|1>", label: "First reveal"),
                        PuzzleStageCheckpoint(move: 2, state: "|0>", label: "Reset"),
                        PuzzleStageCheckpoint(move: 3, state: "|+>", label: "Split rebuilt"),
                        PuzzleStageCheckpoint(move: 4, state: "|->", label: "Sign marked"),
                        PuzzleStageCheckpoint(move: 5, state: "|1>", label: "Second reveal"),
                        PuzzleStageCheckpoint(move: 6, state: "|1>", label: "Same final state")
                    ],
                    stageLabels: ["Reveal the minus sign with H.", "Reset 1 back to 0 with X.", "Split 0 with H.", "Mark the split with Z.", "Reveal the mark with H.", "Apply the final sign mark."]
                ),
                QuantumPuzzle(
                    id: "1.8",
                    title: "Eight-Move Proof",
                    xp: 340,
                    difficulty: "Route 8",
                    puzzleType: "reach-state",
                    objective: "Build the full interference route without taking shortcuts.",
                    concept: "This is the Foundations proof: split, mark, reveal, reset, then prove the route again.",
                    initialState: "|0>",
                    goalState: "|1>",
                    availableGates: ["H", "X", "Z"],
                    solutionGates: ["H", "Z", "H", "X", "H", "Z", "H", "Z"],
                    targetQubits: [:],
                    targetPairs: [:],
                    maxGates: 8,
                    minGates: 0,
                    optimalGates: 8,
                    hintCost: 20,
                    hints: ["The route reaches 1 before it is done. Keep following the proof.", "After the reset, rebuild the same interference pattern.", "Use H, Z, H, X, H, Z, H, Z."],
                    recap: "A locked route can prove the circuit even when a shortcut exists.",
                    chapterNumber: 1,
                    hintTiers: ["The route reaches 1 before it is done. Keep following the proof.", "After the reset, rebuild the same interference pattern.", "Use H, Z, H, X, H, Z, H, Z."],
                    teaches: ["route-locked-proofs", "interference-drill"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "Foundations complete. Daily unlock is now available.",
                    stageFeedback: ["Split made.", "Sign marked.", "You matched the target early; finish the proof.", "Reset complete.", "Split rebuilt.", "Second sign marked.", "Target matched again; one proof step remains.", "Eight-move proof complete."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "8-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H": "That breaks the route. Reset and follow the prompts.", "X": "X would shortcut the first flip. This checkpoint requires the full interference route.", "Z": "Z needs a split to mark. Start the proof with H."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 1, state: "|+>", label: "First split"),
                        PuzzleStageCheckpoint(move: 2, state: "|->", label: "First sign"),
                        PuzzleStageCheckpoint(move: 3, state: "|1>", label: "First reveal"),
                        PuzzleStageCheckpoint(move: 4, state: "|0>", label: "Reset"),
                        PuzzleStageCheckpoint(move: 5, state: "|+>", label: "Second split"),
                        PuzzleStageCheckpoint(move: 6, state: "|->", label: "Second sign"),
                        PuzzleStageCheckpoint(move: 7, state: "|1>", label: "Second reveal"),
                        PuzzleStageCheckpoint(move: 8, state: "|1>", label: "Final state")
                    ],
                    stageLabels: ["Split 0 with H.", "Mark the sign with Z.", "Reveal the mark with H.", "Reset the full bar with X.", "Split again with H.", "Mark the sign again with Z.", "Reveal the mark again with H.", "Apply the final sign mark."]
                )
            ]
        ),
        QubricChapter(
            id: "chapter-2",
            number: 2,
            title: "Linked States",
            theme: "Targeted two-qubit routes",
            summary: "Aim gates at q0/q1 and track CNOT direction across 4-10 move routes.",
            puzzles: [
                QuantumPuzzle(
                    id: "2.0",
                    title: "Aim at q0",
                    xp: 250,
                    difficulty: "Route 4",
                    puzzleType: "reach-state",
                    objective: "Flip q0 through an H-Z-H route, then set q1.",
                    concept: "A targeted gate only acts on its named qubit. H0 is not H1.",
                    initialState: "|00>",
                    goalState: "|11>",
                    availableGates: ["H", "Z", "X"],
                    solutionGates: ["H0", "Z0", "H0", "X1"],
                    targetQubits: ["H": [0, 1], "Z": [0], "X": [1]],
                    targetPairs: [:],
                    maxGates: 4,
                    minGates: 0,
                    optimalGates: 4,
                    hintCost: 20,
                    hints: ["The first three moves build a q0 flip out of H0, Z0, H0.", "Only after q0 is set should q1 move.", "Use H0, Z0, H0, X1."],
                    recap: "Target numbers matter: H0 and H1 are different moves.",
                    chapterNumber: 2,
                    hintTiers: ["The first three moves build a q0 flip out of H0, Z0, H0.", "Only after q0 is set should q1 move.", "Use H0, Z0, H0, X1."],
                    teaches: ["targeted-single-qubit-gates"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You targeted q0 before q1.",
                    stageFeedback: ["Move 1/4 locked: H0. Keep tracing the route.", "Move 2/4 locked: Z0. Keep tracing the route.", "Move 3/4 locked: H0. Keep tracing the route.", "Move 4/4 locked: X1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "4-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "You split the wrong qubit. The target is q0, so the route starts with H0.", "Z0": "Z0 is useful after q0 is split. Start with H0.", "X1": "q1 moves last. Build q0 first."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 3, state: "|10>", label: "q0 built"),
                        PuzzleStageCheckpoint(move: 4, state: "|11>", label: "q1 set")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply Z0.", "Move 3: apply H0.", "Move 4: apply X1."]
                ),
                QuantumPuzzle(
                    id: "2.1",
                    title: "Link and Unlink",
                    xp: 280,
                    difficulty: "Route 5",
                    puzzleType: "reach-state",
                    objective: "Use CNOT direction inside an ordered q0 route.",
                    concept: "CNOT01 copies q0 into q1 only when q0 is on. Direction is part of the gate.",
                    initialState: "|00>",
                    goalState: "|10>",
                    availableGates: ["H", "Z", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0"],
                    targetQubits: ["H": [0], "Z": [0]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 5,
                    minGates: 0,
                    optimalGates: 5,
                    hintCost: 20,
                    hints: ["Split q0, link q1 to it, mark q0, then unlink.", "The second CNOT removes the temporary link before the final H0.", "Use H0, CNOT01, Z0, CNOT01, H0."],
                    recap: "CNOT direction controls which qubit drives the link.",
                    chapterNumber: 2,
                    hintTiers: ["Split q0, link q1 to it, mark q0, then unlink.", "The second CNOT removes the temporary link before the final H0.", "Use H0, CNOT01, Z0, CNOT01, H0."],
                    teaches: ["cnot-direction", "link-unlink"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You linked, marked, unlinked, and revealed q0.",
                    stageFeedback: ["Move 1/5 locked: H0. Keep tracing the route.", "Move 2/5 locked: CNOT01. Keep tracing the route.", "Move 3/5 locked: Z0. Keep tracing the route.", "Move 4/5 locked: CNOT01. Keep tracing the route.", "Move 5/5 locked: H0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "5-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "H0 is correct only at the listed split/reveal steps. Follow the prefix exactly.", "Z0": "Z0 needs q0 in a split or link first. Start with H0.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "CNOT10 points the wrong way. This route needs q0 controlling q1: CNOT01."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 2, state: "BELL_PHI_PLUS", label: "Linked"),
                        PuzzleStageCheckpoint(move: 3, state: "BELL_PHI_MINUS", label: "Marked link"),
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "Unlinked reveal")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0."]
                ),
                QuantumPuzzle(
                    id: "2.2",
                    title: "Crossed Pair",
                    xp: 310,
                    difficulty: "Route 6",
                    puzzleType: "reach-state",
                    objective: "Create a link, cross the pair, then reveal the final state.",
                    concept: "A single-qubit X can change both branches when it is applied inside a linked state.",
                    initialState: "|00>",
                    goalState: "|11>",
                    availableGates: ["H", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "X1", "CNOT01", "H0", "X0"],
                    targetQubits: ["H": [0], "X": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 6,
                    minGates: 0,
                    optimalGates: 6,
                    hintCost: 20,
                    hints: ["Build the link before crossing q1.", "Unlink before the final q0 reveal.", "Use H0, CNOT01, X1, CNOT01, H0, X0."],
                    recap: "Inside a link, a targeted X can move whole branches.",
                    chapterNumber: 2,
                    hintTiers: ["Build the link before crossing q1.", "Unlink before the final q0 reveal.", "Use H0, CNOT01, X1, CNOT01, H0, X0."],
                    teaches: ["branch-crossing", "targeted-x"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "The crossed branches resolved into 11.",
                    stageFeedback: ["Move 1/6 locked: H0. Keep tracing the route.", "Move 2/6 locked: CNOT01. Keep tracing the route.", "Move 3/6 locked: X1. Keep tracing the route.", "Move 4/6 locked: CNOT01. Keep tracing the route.", "Move 5/6 locked: H0. Keep tracing the route.", "Move 6/6 locked: X0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "6-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "X0": "X0 is a later cleanup move. The route starts by splitting q0 with H0.", "X1": "X1 changes branches only after the link exists. Start with H0.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "Wrong CNOT direction. The route uses CNOT01."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 2, state: "BELL_PHI_PLUS", label: "Linked"),
                        PuzzleStageCheckpoint(move: 3, state: "BELL_PSI_PLUS", label: "Crossed"),
                        PuzzleStageCheckpoint(move: 6, state: "|11>", label: "Final pair")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply X1.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply X0."]
                ),
                QuantumPuzzle(
                    id: "2.3",
                    title: "Linked Sign Flip",
                    xp: 340,
                    difficulty: "Route 7",
                    puzzleType: "reach-state",
                    objective: "Mark a linked pair, reveal q0, then set both outputs.",
                    concept: "A phase mark on one side of a link changes the result after the link is undone.",
                    initialState: "|00>",
                    goalState: "|01>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "X1", "X0"],
                    targetQubits: ["H": [0, 1], "X": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 7,
                    minGates: 0,
                    optimalGates: 7,
                    hintCost: 20,
                    hints: ["Build a q0-to-q1 link, then mark q0.", "Undo the link before the final two X moves.", "Use H0, CNOT01, Z0, CNOT01, H0, X1, X0."],
                    recap: "Phase on a link becomes a bit change after unlinking.",
                    chapterNumber: 2,
                    hintTiers: ["Build a q0-to-q1 link, then mark q0.", "Undo the link before the final two X moves.", "Use H0, CNOT01, Z0, CNOT01, H0, X1, X0."],
                    teaches: ["linked-phase", "ordered-cleanup"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You marked the link and cleaned up the outputs.",
                    stageFeedback: ["Move 1/7 locked: H0. Keep tracing the route.", "Move 2/7 locked: CNOT01. Keep tracing the route.", "Move 3/7 locked: Z0. Keep tracing the route.", "Move 4/7 locked: CNOT01. Keep tracing the route.", "Move 5/7 locked: H0. Keep tracing the route.", "Move 6/7 locked: X1. Keep tracing the route.", "Move 7/7 locked: X0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "7-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "H1 splits the wrong qubit. This linked sign route starts at q0.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "X0": "X cleanup comes after the link is undone, not at the start.", "X1": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "CNOT10 points backward for this route. Use CNOT01 when the prompt asks for the link."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 2, state: "BELL_PHI_PLUS", label: "Link built"),
                        PuzzleStageCheckpoint(move: 3, state: "BELL_PHI_MINUS", label: "Link marked"),
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 7, state: "|01>", label: "Cleanup complete")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply X1.", "Move 7: apply X0."]
                ),
                QuantumPuzzle(
                    id: "2.3b",
                    title: "Second Register Reveal",
                    xp: 360,
                    difficulty: "Route 8",
                    puzzleType: "reach-state",
                    objective: "Reveal q0, then use the same H-Z-H proof on q1.",
                    concept: "The H-Z-H proof works on any targeted qubit when you aim it correctly.",
                    initialState: "|00>",
                    goalState: "|11>",
                    availableGates: ["H", "Z", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "H1", "Z1", "H1"],
                    targetQubits: ["H": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 8,
                    minGates: 0,
                    optimalGates: 8,
                    hintCost: 20,
                    hints: ["The first five moves reveal q0.", "The last three moves build X on q1 using H1, Z1, H1.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1."],
                    recap: "Targeted H-Z-H is the same idea on a different qubit.",
                    chapterNumber: 2,
                    hintTiers: ["The first five moves reveal q0.", "The last three moves build X on q1 using H1, Z1, H1.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1."],
                    teaches: ["targeted-proof-transfer"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You transferred the proof from q0 to q1.",
                    stageFeedback: ["Move 1/8 locked: H0. Keep tracing the route.", "Move 2/8 locked: CNOT01. Keep tracing the route.", "Move 3/8 locked: Z0. Keep tracing the route.", "Move 4/8 locked: CNOT01. Keep tracing the route.", "Move 5/8 locked: H0. Keep tracing the route.", "Move 6/8 locked: H1. Keep tracing the route.", "Move 7/8 locked: Z1. Keep tracing the route.", "Move 8/8 locked: H1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "8-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "H1 belongs to the second half. Start with H0 to build the linked q0 proof.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "Z1 needs q1 split first. It is not the opening move.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "Wrong link direction. Use CNOT01 for this proof."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 6, state: "|1+>", label: "q1 split"),
                        PuzzleStageCheckpoint(move: 8, state: "|11>", label: "q1 revealed")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply H1.", "Move 7: apply Z1.", "Move 8: apply H1."]
                ),
                QuantumPuzzle(
                    id: "2.4",
                    title: "Echo the Link",
                    xp: 390,
                    difficulty: "Route 9",
                    puzzleType: "reach-state",
                    objective: "Build two targeted proofs and finish with a controlled echo.",
                    concept: "A final CNOT can use a completed q0 value to toggle q1 one last time.",
                    initialState: "|00>",
                    goalState: "|10>",
                    availableGates: ["H", "Z", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "H1", "Z1", "H1", "CNOT01"],
                    targetQubits: ["H": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 9,
                    minGates: 0,
                    optimalGates: 9,
                    hintCost: 20,
                    hints: ["First reveal q0 with the linked phase route.", "Then reveal q1 with H1, Z1, H1.", "Use the final CNOT01 to echo q0 into q1."],
                    recap: "CNOT can be a temporary link or a final controlled toggle.",
                    chapterNumber: 2,
                    hintTiers: ["First reveal q0 with the linked phase route.", "Then reveal q1 with H1, Z1, H1.", "Use the final CNOT01 to echo q0 into q1."],
                    teaches: ["controlled-echo"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "The controlled echo toggled q1 at the end.",
                    stageFeedback: ["Move 1/9 locked: H0. Keep tracing the route.", "Move 2/9 locked: CNOT01. Keep tracing the route.", "Move 3/9 locked: Z0. Keep tracing the route.", "Move 4/9 locked: CNOT01. Keep tracing the route.", "Move 5/9 locked: H0. Keep tracing the route.", "Move 6/9 locked: H1. Keep tracing the route.", "Move 7/9 locked: Z1. Keep tracing the route.", "Move 8/9 locked: H1. Keep tracing the route.", "Move 9/9 locked: CNOT01. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "9-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "q1 comes after q0 is ready. Start with H0.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "Z1 is part of the q1 proof later in the route.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "The final echo and the link both use q0 controlling q1, not the reverse."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "q0 ready"),
                        PuzzleStageCheckpoint(move: 8, state: "|11>", label: "q1 ready"),
                        PuzzleStageCheckpoint(move: 9, state: "|10>", label: "Echo applied")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply H1.", "Move 7: apply Z1.", "Move 8: apply H1.", "Move 9: apply CNOT01."]
                ),
                QuantumPuzzle(
                    id: "2.5",
                    title: "Bell Builder",
                    xp: 420,
                    difficulty: "Route 9",
                    puzzleType: "reach-state",
                    objective: "Use a Bell link as the middle of a longer exact route.",
                    concept: "Bell links are useful scaffolds: build, mark, unlink, and finish with targeted proofs.",
                    initialState: "|00>",
                    goalState: "|10>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "X1", "H1", "Z1", "H1"],
                    targetQubits: ["H": [0, 1], "X": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 9,
                    minGates: 0,
                    optimalGates: 9,
                    hintCost: 20,
                    hints: ["The Bell link is only the scaffold. Do not stop there.", "After q0 reveals, q1 gets flipped and then proven with H1, Z1, H1.", "Use H0, CNOT01, Z0, CNOT01, H0, X1, H1, Z1, H1."],
                    recap: "A linked state can be an intermediate proof step, not the final answer.",
                    chapterNumber: 2,
                    hintTiers: ["The Bell link is only the scaffold. Do not stop there.", "After q0 reveals, q1 gets flipped and then proven with H1, Z1, H1.", "Use H0, CNOT01, Z0, CNOT01, H0, X1, H1, Z1, H1."],
                    teaches: ["bell-scaffold", "multi-stage-route"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You used the Bell scaffold without stopping on it.",
                    stageFeedback: ["Move 1/9 locked: H0. Keep tracing the route.", "Move 2/9 locked: CNOT01. Keep tracing the route.", "Move 3/9 locked: Z0. Keep tracing the route.", "Move 4/9 locked: CNOT01. Keep tracing the route.", "Move 5/9 locked: H0. Keep tracing the route.", "Move 6/9 locked: X1. Keep tracing the route.", "Move 7/9 locked: H1. Keep tracing the route.", "Move 8/9 locked: Z1. Keep tracing the route.", "Move 9/9 locked: H1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "9-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "H1 belongs to the q1 proof near the end.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "X0": "That breaks the route. Reset and follow the prompts.", "X1": "X1 comes after the Bell scaffold is used. Start with H0.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "CNOT10 builds the wrong scaffold for this route."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 2, state: "BELL_PHI_PLUS", label: "Bell scaffold"),
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 9, state: "|10>", label: "q1 proof completed")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply X1.", "Move 7: apply H1.", "Move 8: apply Z1.", "Move 9: apply H1."]
                ),
                QuantumPuzzle(
                    id: "2.6",
                    title: "Ten-Move Echo",
                    xp: 460,
                    difficulty: "Route 10",
                    puzzleType: "reach-state",
                    objective: "Carry a linked proof through two targeted reveals and a final toggle.",
                    concept: "Longer circuits stay readable when each stage has a job: link, mark, reveal, prove, echo.",
                    initialState: "|00>",
                    goalState: "|11>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "H1", "Z1", "H1", "CNOT01", "X1"],
                    targetQubits: ["H": [0, 1], "X": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 10,
                    minGates: 0,
                    optimalGates: 10,
                    hintCost: 20,
                    hints: ["Moves 1-5 build and reveal q0.", "Moves 6-8 prove q1, then CNOT01 and X1 finish the route.", "Use the route exactly; shorter matching states do not count."],
                    recap: "The budget is exact: every move has to be in the authored route.",
                    chapterNumber: 2,
                    hintTiers: ["Moves 1-5 build and reveal q0.", "Moves 6-8 prove q1, then CNOT01 and X1 finish the route.", "Use the route exactly; shorter matching states do not count."],
                    teaches: ["ten-step-routes", "exact-budget"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You held the route through ten exact moves.",
                    stageFeedback: ["Move 1/10 locked: H0. Keep tracing the route.", "Move 2/10 locked: CNOT01. Keep tracing the route.", "Move 3/10 locked: Z0. Keep tracing the route.", "Move 4/10 locked: CNOT01. Keep tracing the route.", "Move 5/10 locked: H0. Keep tracing the route.", "Move 6/10 locked: H1. Keep tracing the route.", "Move 7/10 locked: Z1. Keep tracing the route.", "Move 8/10 locked: H1. Keep tracing the route.", "Move 9/10 locked: CNOT01. Keep tracing the route.", "Move 10/10 locked: X1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "10-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "The q1 proof starts after q0 is revealed.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "X0": "That breaks the route. Reset and follow the prompts.", "X1": "X1 is the last cleanup move. Starting with it skips the proof.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "This route never uses the reverse CNOT direction."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 5, state: "|10>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 8, state: "|11>", label: "q1 proven"),
                        PuzzleStageCheckpoint(move: 10, state: "|11>", label: "Echo finished")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply H1.", "Move 7: apply Z1.", "Move 8: apply H1.", "Move 9: apply CNOT01.", "Move 10: apply X1."]
                ),
                QuantumPuzzle(
                    id: "2.6b",
                    title: "Offset Register",
                    xp: 470,
                    difficulty: "Route 10",
                    puzzleType: "reach-state",
                    objective: "Start from 01 and carry the same linked proof to 10.",
                    concept: "Changing the starting register changes the meaning of the same controlled route.",
                    initialState: "|01>",
                    goalState: "|10>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "H1", "Z1", "H1", "CNOT01", "X1"],
                    targetQubits: ["H": [0, 1], "X": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 10,
                    minGates: 0,
                    optimalGates: 10,
                    hintCost: 20,
                    hints: ["The route shape is familiar, but the starting register is offset.", "Track q1 carefully after the final CNOT.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1, CNOT01, X1."],
                    recap: "Same route, different start, different meaning.",
                    chapterNumber: 2,
                    hintTiers: ["The route shape is familiar, but the starting register is offset.", "Track q1 carefully after the final CNOT.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1, CNOT01, X1."],
                    teaches: ["same-route-new-start"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "The offset route landed on 10.",
                    stageFeedback: ["Move 1/10 locked: H0. Keep tracing the route.", "Move 2/10 locked: CNOT01. Keep tracing the route.", "Move 3/10 locked: Z0. Keep tracing the route.", "Move 4/10 locked: CNOT01. Keep tracing the route.", "Move 5/10 locked: H0. Keep tracing the route.", "Move 6/10 locked: H1. Keep tracing the route.", "Move 7/10 locked: Z1. Keep tracing the route.", "Move 8/10 locked: H1. Keep tracing the route.", "Move 9/10 locked: CNOT01. Keep tracing the route.", "Move 10/10 locked: X1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "10-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "Even from 01, the route starts by splitting q0 with H0.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "X0": "That breaks the route. Reset and follow the prompts.", "X1": "X1 is the final correction, not the opener.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "The control direction stays q0 to q1."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 5, state: "|11>", label: "q0 revealed from offset"),
                        PuzzleStageCheckpoint(move: 8, state: "|10>", label: "q1 proof inverted"),
                        PuzzleStageCheckpoint(move: 10, state: "|10>", label: "Offset route complete")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply H1.", "Move 7: apply Z1.", "Move 8: apply H1.", "Move 9: apply CNOT01.", "Move 10: apply X1."]
                ),
                QuantumPuzzle(
                    id: "2.7",
                    title: "Reverse Start",
                    xp: 480,
                    difficulty: "Route 10",
                    puzzleType: "reach-state",
                    objective: "Start from 10 and finish the controlled proof on 11.",
                    concept: "A nonzero start makes every controlled toggle matter; route order is the only safe guide.",
                    initialState: "|10>",
                    goalState: "|11>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "Z0", "CNOT01", "H0", "H1", "Z1", "H1", "CNOT01", "X0"],
                    targetQubits: ["H": [0, 1], "X": [0, 1], "Z": [0, 1]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 0]]
                    ],
                    maxGates: 10,
                    minGates: 0,
                    optimalGates: 10,
                    hintCost: 20,
                    hints: ["Do not reason only from the final bars. Trace the route.", "The last move corrects q0 after the final CNOT.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1, CNOT01, X0."],
                    recap: "Starting away from 00 makes route discipline even more important.",
                    chapterNumber: 2,
                    hintTiers: ["Do not reason only from the final bars. Trace the route.", "The last move corrects q0 after the final CNOT.", "Use H0, CNOT01, Z0, CNOT01, H0, H1, Z1, H1, CNOT01, X0."],
                    teaches: ["nonzero-start-controlled-route"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You finished the reverse-start route.",
                    stageFeedback: ["Move 1/10 locked: H0. Keep tracing the route.", "Move 2/10 locked: CNOT01. Keep tracing the route.", "Move 3/10 locked: Z0. Keep tracing the route.", "Move 4/10 locked: CNOT01. Keep tracing the route.", "Move 5/10 locked: H0. Keep tracing the route.", "Move 6/10 locked: H1. Keep tracing the route.", "Move 7/10 locked: Z1. Keep tracing the route.", "Move 8/10 locked: H1. Keep tracing the route.", "Move 9/10 locked: CNOT01. Keep tracing the route.", "Move 10/10 locked: X0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "10-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "q1 moves later. Start by proving q0.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "X0": "X0 is the final correction. The route still starts with H0.", "X1": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT10": "Reverse control is not part of this route."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 5, state: "|00>", label: "q0 proof inverted"),
                        PuzzleStageCheckpoint(move: 8, state: "|01>", label: "q1 proof applied"),
                        PuzzleStageCheckpoint(move: 10, state: "|11>", label: "Reverse start solved")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply Z0.", "Move 4: apply CNOT01.", "Move 5: apply H0.", "Move 6: apply H1.", "Move 7: apply Z1.", "Move 8: apply H1.", "Move 9: apply CNOT01.", "Move 10: apply X0."]
                )
            ]
        ),
        QubricChapter(
            id: "chapter-3",
            number: 3,
            title: "Three-Qubit Routes",
            theme: "GHZ scaffolds and long circuits",
            summary: "Scale the same route discipline to 3-qubit states and 10-15 move proofs.",
            puzzles: [
                QuantumPuzzle(
                    id: "3.1",
                    title: "GHZ Scaffold",
                    xp: 520,
                    difficulty: "Route 10",
                    puzzleType: "reach-state",
                    objective: "Build a GHZ scaffold, unwind it, and land on 011.",
                    concept: "CNOT01 and CNOT12 can extend one split across three qubits.",
                    initialState: "|000>",
                    goalState: "|011>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "CNOT12", "Z2", "CNOT12", "Z1", "CNOT01", "H0", "X2", "X1"],
                    targetQubits: ["H": [0, 1, 2], "X": [0, 1, 2], "Z": [0, 1, 2]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 2], [2, 0], [1, 0], [2, 1], [0, 2]]
                    ],
                    maxGates: 10,
                    minGates: 0,
                    optimalGates: 10,
                    hintCost: 20,
                    hints: ["Moves 1-3 build the GHZ scaffold.", "Moves 4-8 unwind the scaffold back to a register.", "The last two X moves set the requested output."],
                    recap: "A GHZ scaffold spreads one split across three qubits.",
                    chapterNumber: 3,
                    hintTiers: ["Moves 1-3 build the GHZ scaffold.", "Moves 4-8 unwind the scaffold back to a register.", "The last two X moves set the requested output."],
                    teaches: ["three-qubit-ghz", "scaffold-unwind"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You built and unwound a three-qubit scaffold.",
                    stageFeedback: ["Move 1/10 locked: H0. Keep tracing the route.", "Move 2/10 locked: CNOT01. Keep tracing the route.", "Move 3/10 locked: CNOT12. Keep tracing the route.", "Move 4/10 locked: Z2. Keep tracing the route.", "Move 5/10 locked: CNOT12. Keep tracing the route.", "Move 6/10 locked: Z1. Keep tracing the route.", "Move 7/10 locked: CNOT01. Keep tracing the route.", "Move 8/10 locked: H0. Keep tracing the route.", "Move 9/10 locked: X2. Keep tracing the route.", "Move 10/10 locked: X1. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "10-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "The scaffold starts from q0. H1 would split the wrong qubit.", "H2": "The scaffold starts from q0, then spreads through CNOTs.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "Z2": "That breaks the route. Reset and follow the prompts.", "X0": "That breaks the route. Reset and follow the prompts.", "X1": "That breaks the route. Reset and follow the prompts.", "X2": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT12": "That breaks the route. Reset and follow the prompts.", "CNOT20": "q2 is not the first control in this scaffold.", "CNOT10": "The first link must be CNOT01 so q0 controls q1.", "CNOT21": "That breaks the route. Reset and follow the prompts.", "CNOT02": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 3, state: "GHZ_PLUS", label: "GHZ scaffold"),
                        PuzzleStageCheckpoint(move: 4, state: "GHZ_MINUS", label: "Phase-marked GHZ"),
                        PuzzleStageCheckpoint(move: 8, state: "|000>", label: "Scaffold unwound"),
                        PuzzleStageCheckpoint(move: 10, state: "|011>", label: "Output set")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply CNOT12.", "Move 4: apply Z2.", "Move 5: apply CNOT12.", "Move 6: apply Z1.", "Move 7: apply CNOT01.", "Move 8: apply H0.", "Move 9: apply X2.", "Move 10: apply X1."]
                ),
                QuantumPuzzle(
                    id: "3.2",
                    title: "Long Unwind",
                    xp: 580,
                    difficulty: "Route 12",
                    puzzleType: "reach-state",
                    objective: "Mark a GHZ scaffold, unwind it, then prove q2 before the final correction.",
                    concept: "A three-qubit route can combine a global scaffold with a local H-Z-H proof.",
                    initialState: "|000>",
                    goalState: "|001>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "CNOT12", "Z0", "CNOT12", "CNOT01", "H0", "H2", "Z2", "H2", "CNOT12", "X0"],
                    targetQubits: ["H": [0, 1, 2], "X": [0, 1, 2], "Z": [0, 1, 2]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 2], [2, 0], [1, 0], [2, 1], [0, 2]]
                    ],
                    maxGates: 12,
                    minGates: 0,
                    optimalGates: 12,
                    hintCost: 20,
                    hints: ["Build GHZ, mark it, then unwind it through the same links.", "The q2 H-Z-H proof happens after the scaffold is unwound.", "The final X0 corrects the register."],
                    recap: "Scaffolds can be global while proof steps stay local.",
                    chapterNumber: 3,
                    hintTiers: ["Build GHZ, mark it, then unwind it through the same links.", "The q2 H-Z-H proof happens after the scaffold is unwound.", "The final X0 corrects the register."],
                    teaches: ["three-qubit-unwind", "local-proof-after-scaffold"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You completed the 12-move unwind.",
                    stageFeedback: ["Move 1/12 locked: H0. Keep tracing the route.", "Move 2/12 locked: CNOT01. Keep tracing the route.", "Move 3/12 locked: CNOT12. Keep tracing the route.", "Move 4/12 locked: Z0. Keep tracing the route.", "Move 5/12 locked: CNOT12. Keep tracing the route.", "Move 6/12 locked: CNOT01. Keep tracing the route.", "Move 7/12 locked: H0. Keep tracing the route.", "Move 8/12 locked: H2. Keep tracing the route.", "Move 9/12 locked: Z2. Keep tracing the route.", "Move 10/12 locked: H2. Keep tracing the route.", "Move 11/12 locked: CNOT12. Keep tracing the route.", "Move 12/12 locked: X0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "12-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "The GHZ route starts by splitting q0, not q1.", "H2": "q2 is proven later after the scaffold is unwound.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "Z2": "That breaks the route. Reset and follow the prompts.", "X0": "X0 is the final correction, not the opener.", "X1": "That breaks the route. Reset and follow the prompts.", "X2": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT12": "That breaks the route. Reset and follow the prompts.", "CNOT20": "That breaks the route. Reset and follow the prompts.", "CNOT10": "That breaks the route. Reset and follow the prompts.", "CNOT21": "CNOT21 points backward for this scaffold.", "CNOT02": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 3, state: "GHZ_PLUS", label: "GHZ scaffold"),
                        PuzzleStageCheckpoint(move: 4, state: "GHZ_MINUS", label: "Marked GHZ"),
                        PuzzleStageCheckpoint(move: 7, state: "|100>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 10, state: "|101>", label: "q2 proof"),
                        PuzzleStageCheckpoint(move: 12, state: "|001>", label: "Final correction")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply CNOT12.", "Move 4: apply Z0.", "Move 5: apply CNOT12.", "Move 6: apply CNOT01.", "Move 7: apply H0.", "Move 8: apply H2.", "Move 9: apply Z2.", "Move 10: apply H2.", "Move 11: apply CNOT12.", "Move 12: apply X0."]
                ),
                QuantumPuzzle(
                    id: "3.3",
                    title: "Branch Carry",
                    xp: 640,
                    difficulty: "Route 13",
                    puzzleType: "reach-state",
                    objective: "Carry a marked branch through q1 and q2 to finish on 101.",
                    concept: "Once a scaffold is unwound, later CNOTs act on definite register values again.",
                    initialState: "|000>",
                    goalState: "|101>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "CNOT12", "Z2", "CNOT12", "CNOT01", "H0", "H1", "Z1", "H1", "CNOT01", "X2", "CNOT12"],
                    targetQubits: ["H": [0, 1, 2], "X": [0, 1, 2], "Z": [0, 1, 2]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 2], [2, 0], [1, 0], [2, 1], [0, 2]]
                    ],
                    maxGates: 13,
                    minGates: 0,
                    optimalGates: 13,
                    hintCost: 20,
                    hints: ["The first seven moves build, mark, unwind, and reveal q0.", "Then q1 gets its own H-Z-H proof.", "The final CNOTs carry the branch into q2."],
                    recap: "After an unwind, CNOT returns to acting on definite register values.",
                    chapterNumber: 3,
                    hintTiers: ["The first seven moves build, mark, unwind, and reveal q0.", "Then q1 gets its own H-Z-H proof.", "The final CNOTs carry the branch into q2."],
                    teaches: ["branch-carry", "post-scaffold-cnot"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You carried the branch through the long route.",
                    stageFeedback: ["Move 1/13 locked: H0. Keep tracing the route.", "Move 2/13 locked: CNOT01. Keep tracing the route.", "Move 3/13 locked: CNOT12. Keep tracing the route.", "Move 4/13 locked: Z2. Keep tracing the route.", "Move 5/13 locked: CNOT12. Keep tracing the route.", "Move 6/13 locked: CNOT01. Keep tracing the route.", "Move 7/13 locked: H0. Keep tracing the route.", "Move 8/13 locked: H1. Keep tracing the route.", "Move 9/13 locked: Z1. Keep tracing the route.", "Move 10/13 locked: H1. Keep tracing the route.", "Move 11/13 locked: CNOT01. Keep tracing the route.", "Move 12/13 locked: X2. Keep tracing the route.", "Move 13/13 locked: CNOT12. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "13-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "q1's proof starts after q0 is revealed. Start with H0.", "H2": "q2 is carried at the end, not split at the start.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "Z2": "That breaks the route. Reset and follow the prompts.", "X0": "That breaks the route. Reset and follow the prompts.", "X1": "That breaks the route. Reset and follow the prompts.", "X2": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT12": "CNOT12 extends the scaffold after CNOT01. It cannot be first.", "CNOT20": "CNOT20 is off this route's scaffold direction.", "CNOT10": "That breaks the route. Reset and follow the prompts.", "CNOT21": "That breaks the route. Reset and follow the prompts.", "CNOT02": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 3, state: "GHZ_PLUS", label: "GHZ scaffold"),
                        PuzzleStageCheckpoint(move: 4, state: "GHZ_MINUS", label: "Marked scaffold"),
                        PuzzleStageCheckpoint(move: 7, state: "|100>", label: "q0 revealed"),
                        PuzzleStageCheckpoint(move: 10, state: "|110>", label: "q1 proof"),
                        PuzzleStageCheckpoint(move: 13, state: "|101>", label: "Branch carried")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply CNOT12.", "Move 4: apply Z2.", "Move 5: apply CNOT12.", "Move 6: apply CNOT01.", "Move 7: apply H0.", "Move 8: apply H1.", "Move 9: apply Z1.", "Move 10: apply H1.", "Move 11: apply CNOT01.", "Move 12: apply X2.", "Move 13: apply CNOT12."]
                ),
                QuantumPuzzle(
                    id: "3.4",
                    title: "Fifteen-Step Circuit",
                    xp: 720,
                    difficulty: "Route 15",
                    puzzleType: "reach-state",
                    objective: "Complete the full three-qubit proof route.",
                    concept: "Long quantum routes are readable when every stage is a named operation: build, mark, unwind, prove, carry, correct.",
                    initialState: "|000>",
                    goalState: "|110>",
                    availableGates: ["H", "Z", "X", "CNOT"],
                    solutionGates: ["H0", "CNOT01", "CNOT12", "Z2", "CNOT12", "Z1", "CNOT01", "H0", "X2", "H1", "Z1", "H1", "CNOT12", "CNOT01", "X0"],
                    targetQubits: ["H": [0, 1, 2], "X": [0, 1, 2], "Z": [0, 1, 2]],
                    targetPairs: [
                        "CNOT": [[0, 1], [1, 2], [2, 0], [1, 0], [2, 1], [0, 2]]
                    ],
                    maxGates: 15,
                    minGates: 0,
                    optimalGates: 15,
                    hintCost: 20,
                    hints: ["Moves 1-3 build the three-qubit scaffold.", "Moves 4-8 mark and unwind it.", "Moves 9-15 finish with local proof, carries, and correction."],
                    recap: "The route is long because it is a structured proof, not a search.",
                    chapterNumber: 3,
                    hintTiers: ["Moves 1-3 build the three-qubit scaffold.", "Moves 4-8 mark and unwind it.", "Moves 9-15 finish with local proof, carries, and correction."],
                    teaches: ["long-route-discipline", "three-qubit-proof"],
                    strictBudget: true,
                    showMoveTarget: true,
                    showNotation: false,
                    showProbabilities: true,
                    showPhase: true,
                    showGateLabels: true,
                    showMoveDiff: true,
                    explicitTargetButtons: false,
                    solvedMessage: "You completed the 15-step circuit.",
                    stageFeedback: ["Move 1/15 locked: H0. Keep tracing the route.", "Move 2/15 locked: CNOT01. Keep tracing the route.", "Move 3/15 locked: CNOT12. Keep tracing the route.", "Move 4/15 locked: Z2. Keep tracing the route.", "Move 5/15 locked: CNOT12. Keep tracing the route.", "Move 6/15 locked: Z1. Keep tracing the route.", "Move 7/15 locked: CNOT01. Keep tracing the route.", "Move 8/15 locked: H0. Keep tracing the route.", "Move 9/15 locked: X2. Keep tracing the route.", "Move 10/15 locked: H1. Keep tracing the route.", "Move 11/15 locked: Z1. Keep tracing the route.", "Move 12/15 locked: H1. Keep tracing the route.", "Move 13/15 locked: CNOT12. Keep tracing the route.", "Move 14/15 locked: CNOT01. Keep tracing the route.", "Move 15/15 locked: X0. Keep tracing the route."],
                    spotDifference: nil,
                    beforeMovePrompt: nil,
                    firstMovePrompt: nil,
                    activePrompt: nil,
                    practiceLabel: "15-step route",
                    prediction: nil,
                    reflection: nil,
                    qubitLabels: [],
                    wrongGateFeedback: ["H0": "That breaks the route. Reset and follow the prompts.", "H1": "Do not start in the middle. The full circuit begins with H0.", "H2": "q2 is reached through the scaffold first, not by a starting H2.", "Z0": "That breaks the route. Reset and follow the prompts.", "Z1": "That breaks the route. Reset and follow the prompts.", "Z2": "That breaks the route. Reset and follow the prompts.", "X0": "X0 is the final correction. Starting with it skips the circuit.", "X1": "That breaks the route. Reset and follow the prompts.", "X2": "That breaks the route. Reset and follow the prompts.", "CNOT01": "That breaks the route. Reset and follow the prompts.", "CNOT12": "CNOT12 is the second link after CNOT01.", "CNOT20": "CNOT20 is not part of this proof route.", "CNOT10": "That breaks the route. Reset and follow the prompts.", "CNOT21": "That breaks the route. Reset and follow the prompts.", "CNOT02": "That breaks the route. Reset and follow the prompts."],
                    postSolvePrompt: "Reset and try a different first move to see why order matters.",
                    alternateSolutionMessages: [:],
                    enforceSolutionOrder: true,
                    stageCheckpoints: [
                        PuzzleStageCheckpoint(move: 3, state: "GHZ_PLUS", label: "GHZ scaffold"),
                        PuzzleStageCheckpoint(move: 4, state: "GHZ_MINUS", label: "Marked scaffold"),
                        PuzzleStageCheckpoint(move: 8, state: "|000>", label: "Unwound"),
                        PuzzleStageCheckpoint(move: 12, state: "|011>", label: "q1 proof with q2 set"),
                        PuzzleStageCheckpoint(move: 15, state: "|110>", label: "Full route complete")
                    ],
                    stageLabels: ["Move 1: apply H0.", "Move 2: apply CNOT01.", "Move 3: apply CNOT12.", "Move 4: apply Z2.", "Move 5: apply CNOT12.", "Move 6: apply Z1.", "Move 7: apply CNOT01.", "Move 8: apply H0.", "Move 9: apply X2.", "Move 10: apply H1.", "Move 11: apply Z1.", "Move 12: apply H1.", "Move 13: apply CNOT12.", "Move 14: apply CNOT01.", "Move 15: apply X0."]
                )
            ]
        )
    ]

    static var allPuzzles: [QuantumPuzzle] {
        chapters.flatMap(\.puzzles)
    }

    static let firstPuzzleId = "1.1"
    static let dailyUnlockPuzzleId = "1.8"

    static func isDailyEligible(completed: [String: Bool]) -> Bool {
        completed[dailyUnlockPuzzleId] == true
    }

    static func puzzle(id: String) -> QuantumPuzzle? {
        allPuzzles.first { $0.id == id }
    }

    static func nextPuzzleId(after id: String) -> String? {
        guard let index = allPuzzles.firstIndex(where: { $0.id == id }) else { return nil }
        return allPuzzles.dropFirst(index + 1).first?.id
    }

    static func reconciledUnlocked(completed: [String: Bool], unlocked: [String: Bool]) -> [String: Bool] {
        var next = [firstPuzzleId: true]
        for index in allPuzzles.indices {
            let puzzle = allPuzzles[index]
            let previous = index > 0 ? allPuzzles[index - 1] : nil
            if unlocked[puzzle.id] == true || completed[puzzle.id] == true || (previous.map { completed[$0.id] == true } ?? false) {
                next[puzzle.id] = true
            }
        }
        return next
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date())
    }

    static func level(for xp: Int) -> Int {
        (xp / 300) + 1
    }

    static func rank(for xp: Int) -> String {
        if xp >= 2200 { return "Quantum Master" }
        if xp >= 1200 { return "Circuit Strategist" }
        if xp >= 600 { return "Quantum Explorer" }
        if xp >= 200 { return "Qubit Apprentice" }
        return "New Recruit"
    }

    private static func badgeProgress(_ current: Int, _ target: Int, _ unit: String) -> String? {
        let remaining = max(0, target - current)
        guard remaining > 0 else { return nil }
        return "\(remaining) \(unit)\(remaining == 1 ? "" : "s") to go"
    }

    private static func puzzleTitle(_ id: String) -> String {
        puzzle(id: id)?.title ?? id
    }

    static func allBadges(for profile: PlayerProfile) -> [QubricBadge] {
        let completedCount = profile.completed.values.filter { $0 }.count
        let perfectCount = profile.solveStats.values.filter(\.perfect).count
        let reflectionCount = profile.solveStats.values.filter(\.reflectionCorrect).count
        return [
            QubricBadge(
                id: "first-split",
                label: "First Split",
                earned: profile.completed["1.1"] == true,
                progressLabel: profile.completed["1.1"] == true ? nil : "Solve \(puzzleTitle("1.1"))"
            ),
            QubricBadge(
                id: "bell-builder",
                label: "Bell Builder",
                earned: profile.completed["2.5"] == true,
                progressLabel: profile.completed["2.5"] == true ? nil : "Solve \(puzzleTitle("2.5"))"
            ),
            QubricBadge(
                id: "swap-minimalist",
                label: "Swap Minimalist",
                earned: profile.completed["3.2"] == true,
                progressLabel: profile.completed["3.2"] == true ? nil : "Solve \(puzzleTitle("3.2"))"
            ),
            QubricBadge(
                id: "clean-solver",
                label: "Clean Solver",
                earned: perfectCount >= 3,
                progressLabel: perfectCount >= 3 ? nil : badgeProgress(perfectCount, 3, "clean solve")
            ),
            QubricBadge(
                id: "reflective-solver",
                label: "Reflective Solver",
                earned: reflectionCount >= 10,
                progressLabel: reflectionCount >= 10 ? nil : badgeProgress(reflectionCount, 10, "reflection")
            ),
            QubricBadge(
                id: "five-puzzle-streak",
                label: "Five Puzzle Streak",
                earned: completedCount >= 5,
                progressLabel: completedCount >= 5 ? nil : badgeProgress(completedCount, 5, "puzzle")
            ),
            QubricBadge(
                id: "qubric-mastery",
                label: "Qubric Mastery",
                earned: completedCount == allPuzzles.count,
                progressLabel: completedCount == allPuzzles.count ? nil : badgeProgress(completedCount, allPuzzles.count, "puzzle")
            )
        ]
    }

    static func badges(for profile: PlayerProfile) -> [String] {
        allBadges(for: profile).filter(\.earned).map(\.label)
    }

    static func nextMilestone(for profile: PlayerProfile) -> String {
        allBadges(for: profile).first { !$0.earned }?.progressLabel ?? "Every badge earned."
    }
}
