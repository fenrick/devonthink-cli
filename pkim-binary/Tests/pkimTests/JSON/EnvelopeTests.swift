import Foundation
import Testing
@testable import pkim

@Suite("JSON envelope")
struct EnvelopeTests {

    @Test("success envelope encodes with snake_case keys")
    func successSnakeCase() throws {
        struct Payload: Encodable, Sendable { let helloWorld: String }
        let env = SuccessEnvelope(
            verb: "demo",
            runId: "fixed-run-id",
            data: Payload(helloWorld: "hi"),
            warnings: []
        )
        let json = try pkimJsonString(env)
        #expect(json.contains("\"run_id\":\"fixed-run-id\""))
        #expect(json.contains("\"hello_world\":\"hi\""))
        #expect(json.contains("\"ok\":true"))
        #expect(json.contains("\"verb\":\"demo\""))
    }

    @Test("failure envelope encodes with snake_case keys and includes error_type")
    func failureShape() throws {
        let env = FailureEnvelope(
            verb: "demo",
            runId: "fixed-run-id",
            errorType: "InvalidInput",
            errorMessage: "something went wrong",
            context: ["field": "type"]
        )
        let json = try pkimJsonString(env)
        #expect(json.contains("\"ok\":false"))
        #expect(json.contains("\"error_type\":\"InvalidInput\""))
        #expect(json.contains("\"error_message\":\"something went wrong\""))
        #expect(json.contains("\"context\":{\"field\":\"type\"}"))
    }

    @Test("warnings serialise as code+message pairs")
    func warningShape() throws {
        struct Payload: Encodable, Sendable { let ok: Bool }
        let env = SuccessEnvelope(
            verb: "demo",
            runId: "r",
            data: Payload(ok: true),
            warnings: [PkimWarning(code: "stale", message: "cache lag")]
        )
        let json = try pkimJsonString(env)
        #expect(json.contains("\"warnings\":[{\"code\":\"stale\",\"message\":\"cache lag\"}]"))
    }

    @Test("PkimError exposes paired errorType and exitCode")
    func errorPairing() {
        let err: PkimError = .invalidInput("bad", context: ["k": "v"])
        #expect(err.errorType == "InvalidInput")
        #expect(err.exitCode == .invalidInput)
        #expect(err.context == ["k": "v"])
    }
}

@Suite("RunId")
struct RunIdTests {

    @Test("generated value has the expected shape")
    func shape() {
        let runId = RunId.generate(now: Date(timeIntervalSince1970: 1_747_756_324))
        // ISO8601 with internet date time + Z, colons replaced, then -<6hex>
        // 2025-05-20T16:32:04Z → 2025-05-20T16-32-04Z-<6hex>
        let value = runId.value
        #expect(value.hasPrefix("2025-05-20T"))
        #expect(value.contains("Z-"))
        let suffix = value.split(separator: "-").last.map(String.init) ?? ""
        #expect(suffix.count == 6)
        #expect(suffix.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test("two generations differ in the random suffix")
    func uniqueness() {
        // Use the same instant so only the random suffix can vary.
        let now = Date(timeIntervalSince1970: 1_747_756_324)
        let a = RunId.generate(now: now)
        let b = RunId.generate(now: now)
        // Statistically negligible chance of collision on 6 hex chars per call;
        // if this ever flakes, the RNG is broken, not the test.
        #expect(a != b)
    }
}
