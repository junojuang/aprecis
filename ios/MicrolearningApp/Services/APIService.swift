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

    /// Fetches one deck by stable paper_id from GET /serve-cards?paper_id=<id>
    func fetchDeck(paperId: String) async throws -> CardDeck {
        let encoded = paperId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? paperId
        let request = try makeRequest(path: "/serve-cards?paper_id=\(encoded)")
        return try await perform(request)
    }

    // MARK: - Related graph

    /// Backend Explore rails for one paper. Keys match the JSON exactly, so no
    /// CodingKeys mapping is needed. Every value is a paper_id in the corpus.
    struct RelatedResponse: Decodable {
        let buildsOn: [String]
        let ledTo: [String]
        let adjacent: [String]
        let surprise: String?
    }

    /// GET /serve-cards/related?paperId=<id> — citation lineage + embedding
    /// neighbors for the Explore hub rails.
    func fetchRelated(paperId: String) async throws -> RelatedResponse {
        let encoded = paperId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? paperId
        let request = try makeRequest(path: "/serve-cards/related?paperId=\(encoded)")
        return try await perform(request)
    }

    // MARK: - Add Paper

    /// POST /add-paper with an arXiv ID, runs the full pipeline, returns the CardDeck.
    func addPaper(arxivId: String) async throws -> CardDeck {
        struct Body: Encodable { let arxiv_id: String }
        let bodyData = try JSONEncoder().encode(Body(arxiv_id: arxivId))
        let request = try makeRequest(path: "/add-paper", method: "POST", body: bodyData)
        return try await perform(request)
    }

    // MARK: - arXiv Search (direct public API, no auth needed)

    struct ArxivPaper: Identifiable {
        let id: String          // e.g. "2301.07041"
        let title: String
        let authors: [String]
        let abstract: String
        let published: Date
    }

    func searchArxiv(query: String) async throws -> [ArxivPaper] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://export.arxiv.org/api/query?search_query=ti:\(encoded)+OR+abs:\(encoded)&max_results=15&sortBy=relevance&sortOrder=descending"
        guard let url = URL(string: urlStr) else { throw APIError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        let xml = String(data: data, encoding: .utf8) ?? ""
        return parseArxivXML(xml)
    }

    private func parseArxivXML(_ xml: String) -> [ArxivPaper] {
        // Split by <entry>, first chunk is the feed header, skip it
        let entries = xml.components(separatedBy: "<entry>").dropFirst()
        let isoParser = ISO8601DateFormatter()
        return entries.compactMap { entry in
            guard
                let rawId    = entry.xmlText("id"),
                let title    = entry.xmlText("title"),
                let summary  = entry.xmlText("summary")
            else { return nil }

            // arXiv IDs look like: http://arxiv.org/abs/2301.07041v2
            let arxivId = rawId
                .components(separatedBy: "/abs/").last?
                .replacingOccurrences(of: #"v\d+$"#, with: "", options: .regularExpression)
                ?? rawId

            let authorBlocks = entry.components(separatedBy: "<author>").dropFirst()
            let authors = authorBlocks.compactMap { $0.xmlText("name") }

            let published = entry.xmlText("published")
                .flatMap { isoParser.date(from: $0) } ?? Date()

            return ArxivPaper(
                id: arxivId,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\n", with: " "),
                authors: Array(authors.prefix(4)),
                abstract: summary.trimmingCharacters(in: .whitespacesAndNewlines)
                                 .replacingOccurrences(of: "\n", with: " "),
                published: published
            )
        }
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

// MARK: - XML helpers

private extension String {
    /// Extract the text content of the first occurrence of `<tag>...</tag>`.
    func xmlText(_ tag: String) -> String? {
        guard
            let start = range(of: "<\(tag)>") ?? range(of: "<\(tag) "),
            let closeTag = range(of: "</\(tag)>")
        else { return nil }
        // If the opening tag has attributes, advance past the ">"
        var contentStart = start.upperBound
        if self[start].last != ">" {
            guard let gt = range(of: ">", range: contentStart..<endIndex) else { return nil }
            contentStart = gt.upperBound
        }
        guard contentStart <= closeTag.lowerBound else { return nil }
        return String(self[contentStart..<closeTag.lowerBound])
    }
}
