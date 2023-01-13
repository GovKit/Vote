import Fluent
import Vapor

/// User model that conforms to `Model` and `Content` protocols
final class User: Model, Content {
    /// Schema name for the users table
    static let schema = "users"

    /// ID property for the user, conforms to `ID` protocol
    @ID(key: .id)
    var id: UUID?

    /// Name property for the user
    @Field(key: "name")
    var name: String

    /// Email property for the user
    @Field(key: "email")
    var email: String

    /// PasswordHash property for the user
    @Field(key: "password_hash")
    var passwordHash: String

    /// Initializer for creating a new User instance
    init() { }

    /// Initializer for creating a new User instance with an ID, name, email and password hash
    ///
    /// - Parameters:
    ///   - id: Optional UUID for the user
    ///   - name: Name of the user
    ///   - email: Email of the user
    ///   - passwordHash: Hashed password of the user
    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

/// Extension to conform to `ModelUser` protocol
extension User: ModelUser {
    /// Key path to the email property
    static let usernameKey = \User.$email
    /// Key path to the passwordHash property
    static let passwordHashKey = \User.$passwordHash

    /// Function to verify password
    ///
    /// - Parameters:
    ///   - password: plain text password
    /// - Returns:
    ///   - Bool: returns true if the password is correct else false
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
