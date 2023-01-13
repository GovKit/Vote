import Fluent
import Vapor

final class UserToken: Model, Content {
    /**
     Static variable for the schema name of the user token
     */
    static let schema = "user_tokens"

    /**
     ID variable for the user token, with a default key of "id"
     */
    @ID(key: .id)
    var id: UUID?

    /**
     Value variable for the user token, with a default key of "value"
     */
    @Field(key: "value")
    var value: String

    /**
     User variable for the user token, with a default key of "user_id"
     */
    @Parent(key: "user_id")
    var user: User

    /**
     Initializer for UserToken
     */
    init() { }

    /**
     Initializer for UserToken with parameters for the id, value, and user id
     - Parameter id: The id of the user token
     - Parameter value: The value of the user token
     - Parameter userID: The user id associated with the user token
     */
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
    }
}

/**
 Extension for UserToken, conforming to ModelUserToken.
 */
extension UserToken: ModelUserToken {
    /**
     Static variable for the value key
     */
    static let valueKey = \UserToken.$value
    /**
     Static variable for the user key
     */
    static let userKey = \UserToken.$user

    /**
     A variable that returns true if the token is valid
     */
    var isValid: Bool {
        return true
    }
}

/**
 Extension for User, providing a function to generate a token
 */
extension User {
    /**
     Function to generate a token for the user
     - Throws: Errors if there is a problem generating the token
     - Returns: A new UserToken
     */
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
