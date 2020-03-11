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

    func testLogin() throws {
        let headers: HTTPHeaders = ["Authorization": "Basic dGVzdEB0ZXN0LmNvbTp0ZXN0aW5nUGFzc3dvcmQ="]
        try register(app: app) { _ in
            try app.test(.POST, "login", headers: headers) { res in
                XCTAssertEqual(res.status, .ok)
                let token = try res.content.decode(UserTokenResponse.self)
                XCTAssertTrue(token.value != "")
            }
        }
    }

    func testCreateElection() throws {
        try login(app: app) { token in
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
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token.value)",
                                    "content-type": "application/json"]
        return headers
    }

    func register(app: Application, onComplete: (XCTHTTPResponse) throws -> Void) throws {
        let body = try CreateUserRequest(name: "David",
                                   email: "test@test.com",
                                   password: "thisPassword",
                                   confirmPassword: "thisPassword").asByteBuffer()
        try app.test(.POST, "register", headers: ["content-type": "application/json"], body: body) { res in
            try onComplete(res)
        }
    }

    func login(app: Application, onComplete: (UserTokenResponse) throws -> Void) throws {
        let body = try CreateUserRequest(name: "David",
                                   email: "test@test.com",
                                   password: "thisPassword",
                                   confirmPassword: "thisPassword").asByteBuffer()
        try app.test(.POST, "register", headers: ["content-type": "application/json"], body: body) { _ in
            let headers: HTTPHeaders = ["Authorization": "Basic dGVzdEB0ZXN0LmNvbTp0ZXN0aW5nUGFzc3dvcmQ="]
            try register(app: app) { _ in
                try app.test(.POST, "login", headers: headers) { res in
                    let token = try res.content.decode(UserTokenResponse.self)
                    try onComplete(token)
                }
            }

        }
    }

}
