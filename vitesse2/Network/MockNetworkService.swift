//
//  MockNetworkService.swift
//  vitesse2
//
//  Created by TLiLi Hamdi on 18/12/2024.
//

import Foundation

class MockNetworkService: NetworkServiceProtocol {
    var mockResponses: [URL: Result<Data, Error>] = [:]
    var token: String?
    
    func setToken(_ token: String) async {
        self.token = token
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkService.NetworkError.invalidURL
        }
        
        if endpoint.requiresAuthentication && token == nil {
            throw NetworkService.NetworkError.missingToken
        }
        
        guard let result = mockResponses[url] else {
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
        guard let url = endpoint.url else {
            throw NetworkService.NetworkError.invalidURL
        }
        
        if endpoint.requiresAuthentication && token == nil {
            throw NetworkService.NetworkError.missingToken
        }
        
        guard let result = mockResponses[url] else {
            throw NetworkService.NetworkError.unknown
        }
        
        if case .failure(let error) = result {
            throw error
        }
    }
}
