import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)

    addMigrations(app)

    // register routes
    try routes(app)
}


private func addMigrations(_ app: Application) {
    app.migrations.add(CreateBallot())
    app.migrations.add(CreateBallotItem())
    app.migrations.add(CreateBallotOption())
    app.migrations.add(CreateElection())
    app.migrations.add(CreateSubmission())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    app.migrations.add(CreateVoter())
}
