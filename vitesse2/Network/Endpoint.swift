import Foundation

enum Endpoint {
    case login(email: String, password: String)
    case register(email: String, password: String, firstName: String, lastName: String)
    case verifyToken
    case candidates
    case candidate(id: String)
    case createCandidate(_ candidate: CandidateRequest)
    case updateCandidate(id: String, candidate: CandidateRequest)
    case deleteCandidate(id: String)
    case toggleFavorite(id: String)
}

extension Endpoint {
    private var baseURL: String { "http://127.0.0.1:8080" }
    
    var path: String {
        switch self {
        case .login:
            return "/user/auth"
        case .register:
            return "/user/register"
        case .verifyToken:
            return "/user/verify-token"
        case .candidates:
            return "/candidate"
        case .candidate(let id):
            return "/candidate/\(id)"
        case .createCandidate:
            return "/candidate"
        case .updateCandidate(let id, _):
            return "/candidate/\(id)"
        case .deleteCandidate(let id):
            return "/candidate/\(id)"
        case .toggleFavorite(let id):
            return "/candidate/\(id)/favorite"
        }
    }
    
    var method: String {
        switch self {
        case .login, .register, .createCandidate, .toggleFavorite:
            return "POST"
        case .candidates, .candidate, .verifyToken:
            return "GET"
        case .updateCandidate:
            return "PUT"
        case .deleteCandidate:
            return "DELETE"
        }
    }
    
    var url: URL? {
        URL(string: baseURL + path)
    }
    
    var requiresAuthentication: Bool {
        switch self {
        case .login, .register:
            return false
        default:
            return true
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let email, let password):
            return LoginRequest(email: email, password: password)
        case .register(let email, let password, let firstName, let lastName):
            return RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName)
        case .createCandidate(let candidate), .updateCandidate(_, let candidate):
            return candidate
        default:
            return nil
        }
    }
}
