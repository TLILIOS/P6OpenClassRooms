import Foundation


protocol NetworkServiceProtocol: Sendable {
//    func setToken(_ token: String) async
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestWithoutResponse(_ endpoint: Endpoint) async throws
}
actor NetworkService {
    static let shared = NetworkService()
    private var token: String? {
        get { TokenManager.shared.getToken() }
    }
    
    private init() {}
    
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case unauthorized
        case serverError(Int, String?)
        case decodingError(Error)
        case unknown
        case missingToken
        
        var message: String {
            switch self {
            case .invalidURL:
                return "URL invalide"
            case .invalidResponse:
                return "Réponse invalide du serveur"
            case .unauthorized:
                return "Non autorisé"
            case .serverError(let code, let message):
                return message ?? "Erreur serveur: \(code)"
            case .decodingError(let error):
                return "Erreur de décodage: \(error.localizedDescription)"
            case .unknown:
                return "Erreur inconnue"
            case .missingToken:
                return "Token d'authentification manquant"
            }
        }
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        // Vérifier si nous avons besoin d'un token pour cet endpoint
        if endpoint.requiresAuthentication {
            guard let token = token else {
                print("Token missing for authenticated endpoint: \(endpoint)")
                throw NetworkError.missingToken
            }
            print("Using token for request: \(String(token.prefix(10)))...")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Added Authorization header: Bearer \(String(token.prefix(10)))...")
        }
        
        if let body = endpoint.body {
            let jsonData = try? JSONEncoder().encode(body)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData!, encoding: .utf8) {
                print("Request body: \(jsonString)")
            }
        }
        
        print("Making request to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 201 where T.self == EmptyResponse.self:
            return EmptyResponse() as! T
        case 200...299:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                print("Response data that failed to decode: \(String(data: data, encoding: .utf8) ?? "none")")
                throw NetworkError.decodingError(error)
            }
        case 401:
            print("Unauthorized error - clearing token")
            TokenManager.shared.clearToken()
            throw NetworkError.unauthorized
        case 400...499:
            let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data).message
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        case 500...599:
            print("Server error \(httpResponse.statusCode)")
            throw NetworkError.serverError(httpResponse.statusCode, nil)
        default:
            throw NetworkError.unknown
        }
    }
    
    func requestWithoutResponse(_ endpoint: Endpoint) async throws {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }
        
        if endpoint.requiresAuthentication {
            guard let token = token else {
                print("Token missing for authenticated endpoint: \(endpoint)")
                throw NetworkError.missingToken
            }
            print("Using token for request: \(String(token.prefix(10)))...")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Added Authorization header: Bearer \(String(token.prefix(10)))...")
        }
        
        if let body = endpoint.body {
            let jsonData = try? JSONEncoder().encode(body)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData!, encoding: .utf8) {
                print("Request body: \(jsonString)")
            }
        }
        
        print("Making request to: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response data: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            print("Unauthorized error - clearing token")
            TokenManager.shared.clearToken()
            throw NetworkError.unauthorized
        case 400...499:
            let errorMessage = try? JSONDecoder().decode(ErrorResponse.self, from: data).message
            throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
        case 500...599:
            print("Server error \(httpResponse.statusCode)")
            throw NetworkError.serverError(httpResponse.statusCode, nil)
        default:
            throw NetworkError.unknown
        }
    }
}

struct ErrorResponse: Codable {
    let message: String
}

struct EmptyResponse: Codable {}

extension NetworkService: NetworkServiceProtocol {}
