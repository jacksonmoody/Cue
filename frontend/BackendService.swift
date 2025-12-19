//
//  BackendService.swift
//  Cue
//
//  Created by Jackson Moody on 12/15/25.
//

import Foundation

enum BackendError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknownError
}

class BackendService {
    static let shared = BackendService()
    
    private let baseURLString = "https://cue-api.vercel.app"
    
    private init() {}
    
    private var baseURL: URL? {
        return URL(string: baseURLString)
    }
    
    private func createRequest(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) throws -> URLRequest {
        guard let baseURL = baseURL else {
            throw BackendError.invalidURL
        }
        
        // Handle paths that start with "/" or don't
        let url: URL
        if path.hasPrefix("/") {
            // Absolute path - construct full URL
            guard let fullURL = URL(string: baseURLString + path) else {
                throw BackendError.invalidURL
            }
            url = fullURL
        } else {
            // Relative path - append to base URL
            url = baseURL.appendingPathComponent(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    // MARK: - Async Request Methods
    
    func post<T: Decodable>(
        path: String,
        body: [String: Any]? = nil,
        responseType: T.Type
    ) async throws -> T {
        let request = try createRequest(path: path, method: "POST", body: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw BackendError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw BackendError.decodingError(error)
            }
        } catch let error as BackendError {
            throw error
        } catch {
            throw BackendError.networkError(error)
        }
    }
    
    func get<T: Decodable>(
        path: String,
        responseType: T.Type
    ) async throws -> T {
        let request = try createRequest(path: path, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw BackendError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw BackendError.decodingError(error)
            }
        } catch let error as BackendError {
            throw error
        } catch {
            throw BackendError.networkError(error)
        }
    }
    
    func post(
        path: String,
        body: [String: Any]? = nil,
        completion: @escaping (Result<Void, BackendError>) -> Void
    ) {
        do {
            let request = try createRequest(path: path, method: "POST", body: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                completion(.success(()))
            }.resume()
        } catch {
            if let backendError = error as? BackendError {
                completion(.failure(backendError))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
    
    func postWithResponse<T: Decodable>(
        path: String,
        body: [String: Any]? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, BackendError>) -> Void
    ) {
        do {
            let request = try createRequest(path: path, method: "POST", body: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(.serverError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(.decodingError(error)))
                }
            }.resume()
        } catch {
            if let backendError = error as? BackendError {
                completion(.failure(backendError))
            } else {
                completion(.failure(.unknownError))
            }
        }
    }
}

