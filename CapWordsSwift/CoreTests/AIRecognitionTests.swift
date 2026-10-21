import XCTest
@testable import CapWordsCore

final class AIRecognitionTests: XCTestCase {
    private var configuration: AIRecognitionConfiguration {
        .init(baseURL: "https://api.deepseek.com", model: "deepseek-flash", apiKey: "test-key")
    }

    func testImageRequestUsesOfficialProtocol() throws {
        let request = try AIRecognitionClient().request(image: Data([1, 2, 3]), languageCode: "ja-JP", scene: false,
                                                        configuration: configuration)
        XCTAssertEqual(request.url?.absoluteString, "https://api.deepseek.com/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["model"] as? String, "deepseek-flash")
        let messages = try XCTUnwrap(body["messages"] as? [[String: Any]])
        XCTAssertTrue((messages[0]["content"] as? String)?.contains("ja-JP") == true)
        let content = try XCTUnwrap(messages[1]["content"] as? [[String: Any]])
        XCTAssertEqual((content[1]["image_url"] as? [String: String])?["url"], "data:image/jpeg;base64,AQID")
    }

    func testConfigurationRejectsUnsafeOrMissingValues() throws {
        for address in ["http://api.deepseek.com", "https://user:password@example.com", "https://example.com?key=secret", ""] {
            var config = configuration; config.baseURL = address
            XCTAssertThrowsError(try config.endpoint())
        }
        var config = configuration; config.apiKey = " "
        XCTAssertThrowsError(try config.endpoint())
        config = configuration; config.baseURL = "https://example.com/v1/"
        XCTAssertEqual(try config.endpoint().absoluteString, "https://example.com/v1/chat/completions")
    }

    func testNativeLanguageChangesTranslationsWithoutChangingTargetOrCategories() throws {
        let request = try AIRecognitionClient().request(image: Data([1]), languageCode: "ja-JP", scene: false,
            configuration: configuration, nativeLanguageCode: "fr-FR")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        let messages = try XCTUnwrap(body["messages"] as? [[String: Any]])
        let prompt = try XCTUnwrap(messages.first?["content"] as? String)
        XCTAssertTrue(prompt.contains("目标语言代码：ja-JP，母语代码：fr-FR"))
        XCTAssertTrue(prompt.contains("meaning、exampleMeaning 使用母语 fr-FR"))
        XCTAssertTrue(prompt.contains("category 始终使用简体中文"))
    }

    private func response(language: String = "en-US", needsNaming: Bool = false, name: String = "cup", meaning: String = "杯子", finish: String = "stop") throws -> Data {
        let entry = AIWordEntry(name: name, meaning: meaning, pronunciation: "/kʌp/", example: "Bring me a cup.",
                                exampleMeaning: "给我拿个杯子。", category: "日常", languageCode: language, needsNaming: needsNaming)
        let content = String(decoding: try JSONEncoder().encode(entry), as: UTF8.self)
        return try JSONSerialization.data(withJSONObject: ["choices": [["finish_reason": finish, "message": ["content": content]]]])
    }

    func testValidWordAndUncertainWord() throws {
        let word = try AIRecognitionClient.decode(response(), languageCode: "en-US")
        XCTAssertEqual(word.name, "cup")
        XCTAssertEqual(word.meaning, "杯子")
        XCTAssertEqual(word.exampleMeaning, "给我拿个杯子。")
        let uncertain = try AIRecognitionClient.decode(response(needsNaming: true), languageCode: "en-US")
        XCTAssertTrue(uncertain.needsNaming)
        XCTAssertTrue(uncertain.name.isEmpty)
        XCTAssertTrue(uncertain.example.isEmpty)
    }

    func testRejectsWrongLanguageEmptyNameTruncationAndMalformedResponse() throws {
        XCTAssertThrowsError(try AIRecognitionClient.decode(response(language: "ja-JP"), languageCode: "en-US"))
        XCTAssertThrowsError(try AIRecognitionClient.decode(response(name: " "), languageCode: "en-US"))
        XCTAssertThrowsError(try AIRecognitionClient.decode(response(meaning: " \n "), languageCode: "en-US"))
        XCTAssertThrowsError(try AIRecognitionClient.decode(response(finish: "length"), languageCode: "en-US"))
        XCTAssertThrowsError(try AIRecognitionClient.decode(Data("{}".utf8), languageCode: "en-US"))
    }
}

private final class RecognitionMockProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let path = request.url!.path
        if path.contains("timeout") {
            client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
        } else if path.contains("cancel") {
            client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
        } else {
            let status = path.contains("401") ? 401 : 429
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status,
                                                                 httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("sensitive-provider-error".utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() { }
}

extension AIRecognitionTests {
    func testTransportErrorsAndCancellation() async throws {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [RecognitionMockProtocol.self]
        let session = URLSession(configuration: sessionConfiguration)
        defer { session.invalidateAndCancel() }
        let client = AIRecognitionClient(session: session)
        for route in ["401", "429", "timeout", "cancel"] {
            var config = configuration
            config.baseURL = "https://mock.invalid/\(route)"
            do {
                _ = try await client.recognize(image: Data([1]), languageCode: "en-US", scene: false, configuration: config)
                XCTFail("Expected error for \(route)")
            } catch is CancellationError {
                XCTAssertEqual(route, "cancel")
            } catch let error as AIRecognitionError {
                XCTAssertFalse(error.localizedDescription.contains("sensitive-provider-error"))
                switch (route, error) {
                case ("401", .http(401)), ("429", .http(429)), ("timeout", .timeout): break
                default: XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }
}
