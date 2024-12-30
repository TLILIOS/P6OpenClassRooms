import Foundation

// Modèle pour la création d'un utilisateur
struct UserRegistration: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

// Modèle pour un utilisateur connecté
struct User: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    
    // Méthode de validation de l'email
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
