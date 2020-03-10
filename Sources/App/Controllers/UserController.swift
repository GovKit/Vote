import Fluent
import Vapor

struct UserController {
    func create(req: Request) throws -> EventLoopFuture<UserToken> {
        try User.Create.validate(req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        let user = try User(
            name: create.name,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        return user.save(on: req.db)
            .flatMap {
                do {
                    return try self.token(for: user, db: req.db)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
        }
    }

    func login(req: Request) throws -> EventLoopFuture<UserToken> {
        let user = try req.auth.require(User.self)
        return try token(for: user, db: req.db)
    }

    func token(for user: User, db: Database) throws -> EventLoopFuture<UserToken> {
        let token = try user.generateToken()
        return token.save(on: db)
            .map { token }
    }
}

extension User {
    struct Create: Content {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
    }

    struct Response {
        var name: String
        var email: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
