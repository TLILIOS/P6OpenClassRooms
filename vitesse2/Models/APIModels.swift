import Foundation

// Modèle pour les candidats
struct Candidate: Codable, Identifiable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var note: String?
    var linkedinURL: String?
    var isFavorite: Bool
    
    // Propriété locale non incluse dans le codage/décodage
    var isSelected: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, email, phone, note, linkedinURL, isFavorite
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    // Implementation de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Candidate, rhs: Candidate) -> Bool {
        lhs.id == rhs.id
    }
}
