import Foundation

struct CandidateRequest: Codable {
    let email: String
    let note: String?
    let linkedinURL: String?
    let firstName: String
    let lastName: String
    let phone: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

struct EmptyRequest: Codable {}

struct FavoriteRequest: Codable {
    let isFavorite: Bool
}
