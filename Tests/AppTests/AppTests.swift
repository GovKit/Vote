@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    var app: Application!

    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application(.testing)
        try configure(app)
    }

    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }

    func testHelloWorld() throws {
        try app.test(.GET, "hello") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        }
    }

    func testRegister() throws {
        try register(app: app) { token in
            XCTAssertTrue(token.value != "")
        }
    }

    func testLogin() throws {

        let basicAuth = "test@test.com:thisPassword".data(using: .utf8)
        let headers: HTTPHeaders = ["Authorization": "Basic \(basicAuth?.base64EncodedString() ?? "")"]
        try register(app: app) { _ in
            try app.test(.POST, "login", headers: headers) { res in
                let token = try res.content.decode(UserTokenResponse.self)
                XCTAssertTrue(token.value != "")
                XCTAssertEqual(res.status, .ok)
            }
        }
    }

    func testCreateElection() throws {
        try register(app: app) { token in
            let headers = standardHeaders(with: token)
            let body = try CreateElectionRequest(description: "Test Election").asByteBuffer()
            try app.test(.POST, "elections", headers: headers, body: body) { res in
                let election = try res.content.decode(Election.self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(election.description, "Test Election")
            }
        }
    }
}

extension Content {
    func asByteBuffer() throws -> ByteBuffer {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        try JSONEncoder().encode(self, into: &body)
        return body
    }
}

extension XCTestCase {
    func standardHeaders(with token: UserTokenResponse) -> HTTPHeaders {
        let headers: HTTPHeaders = ["content-type": "application/json",
                                   "Authorization": "Bearer \(token.value)"]
        return headers
    }

    func register(app: Application, onComplete: (UserTokenResponse) throws -> Void) throws {
        let body = try CreateUserRequest(name: "David",
                                   email: "test@test.com",
                                   password: "thisPassword",
                                   confirmPassword: "thisPassword").asByteBuffer()
        try app.test(.POST, "register", headers: ["content-type": "application/json"], body: body) { res in
            let token = try res.content.decode(UserTokenResponse.self)
            try onComplete(token)
        }
    }

}
