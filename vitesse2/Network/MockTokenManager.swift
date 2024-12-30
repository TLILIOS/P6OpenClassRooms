
import Foundation



class MockTokenManager: TokenManagerProtocol {
    var token: String?
    var shouldFailToSaveToken: Bool = false

    func getToken() -> String? {
        return shouldFailToSaveToken ? nil : token
    }

    func saveToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }
}
