import AppKit
import Vision

// swift -module-cache-path /tmp/capwords-result-ocr-cache scripts/verify_result_text.swift CAPTURE_DIRECTORY
let directory = URL(fileURLWithPath: CommandLine.arguments[1])
let fixtures = [("donut", "甜甜圈"), ("key", "钥匙"), ("long", "无线游戏手柄"), ("missing", "补充中文名称"), ("slow", "甜甜圈")]
var records: [[String: Any]] = []
for (name, expected) in fixtures {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["zh-Hans", "en-US"]
    let url = directory.appendingPathComponent("\(name).png")
    try VNImageRequestHandler(url: url).perform([request])
    let observations = request.results ?? []
    let match = observations.first { observation in
        observation.topCandidates(1).first?.string.replacingOccurrences(of: " ", with: "").contains(expected) == true
    }
    guard let match else {
        fatalError("\(name): missing visible Chinese name \(expected); OCR=\(observations.compactMap { $0.topCandidates(1).first?.string })")
    }
    let bottom = 1 - match.boundingBox.minY
    // Video 4's large confirmation circle starts around y=.49. Leave clear space above it.
    precondition(bottom < 0.485, "\(name): Chinese name overlaps the action controls")
    records.append(["fixture": name, "expected": expected, "recognized": match.topCandidates(1).first!.string, "bottom": bottom, "passed": true])
}
let result = try JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys])
try result.write(to: directory.appendingPathComponent("text-validation.json"))
print(String(decoding: result, as: UTF8.self))
