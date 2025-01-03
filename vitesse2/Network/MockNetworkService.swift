//
//  MockNetworkService.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 18/12/2024.
//

import Foundation

class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var mockResponses:  Result<Data, Error>?
    var token: String?
    var mockError: Error?
    
    func setToken(_ token: String) async {
        self.token = token
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        if let error = mockError {
            throw error
        }
        
        guard let url = endpoint.url else {
            throw NetworkService.NetworkError.invalidURL
        }
        
        if endpoint.requiresAuthentication && token == nil {
            throw NetworkService.NetworkError.missingToken
        }
        
        guard let result = mockResponses else {
            throw NetworkService.NetworkError.unknown
        }
        
        switch result {
        case .success(let data):
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkService.NetworkError.decodingError(error)
            }
        case .failure(let error):
            throw error
        }
    }
    
    func requestWithoutResponse(_ endpoint: Endpoint) async throws {
        if let error = mockError {
            throw error
        }
        
        guard let url = endpoint.url else {
            throw NetworkService.NetworkError.invalidURL
        }
        
        if endpoint.requiresAuthentication && token == nil {
            throw NetworkService.NetworkError.missingToken
        }
        
        guard let result = mockResponses else {
            throw NetworkService.NetworkError.unknown
        }
        
        if case .failure(let error) = result {
            throw error
        }
    }
}
