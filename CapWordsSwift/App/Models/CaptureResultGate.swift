import Foundation

/// 词条与展示独立到达；确认、展开完成、词条就绪三者齐备才揭示一次结果。
struct CaptureResultGate: Sendable {
    private(set) var confirmed = false
    private(set) var transitionFinished = false
    private(set) var wordReady = false
    private(set) var revealed = false
    mutating func confirm() { confirmed = true }
    mutating func finishTransition() { transitionFinished = true }
    mutating func receiveWord() { wordReady = true }
    mutating func takeReveal() -> Bool {
        guard confirmed, transitionFinished, wordReady, !revealed else { return false }
        revealed = true
        return true
    }
}
