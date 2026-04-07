import Foundation

// MARK: - Interaction Type

enum InteractionType: String, Codable {
    case swipedLeft = "swiped_left"
    case swipedRight = "swiped_right"
    case saved
    case shared
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .invalidResponse(let code):
            return "Server returned an unexpected status code: \(code)."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - APIService

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Private helpers

    private func makeRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(Config.apiBase)\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = body
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Public API

    /// Fetches a page of card decks from GET /serve-cards?page=<page>
    struct FeedPage: Decodable {
        let decks: [CardDeck]
        let has_more: Bool
    }

    func fetchFeed(page: Int) async throws -> FeedPage {
        let request = try makeRequest(path: "/serve-cards?page=\(page)")
        return try await perform(request)
    }

    /// Records a user interaction via POST /serve-cards/interaction
    func markInteraction(paperId: String, action: InteractionType) async throws {
        struct Body: Encodable {
            let paper_id: String
            let action: String
        }
        let body = Body(paper_id: paperId, action: action.rawValue)
        let bodyData = try JSONEncoder().encode(body)
        let request = try makeRequest(path: "/serve-cards/interaction", method: "POST", body: bodyData)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.invalidResponse(statusCode: http.statusCode)
        }
        _ = data
    }
}
