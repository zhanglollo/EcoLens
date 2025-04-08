//
//  OpenAIVisionService.swift
//  ecolens
//
//  Created by Litong Zhang on 2025-04-08.
//

import UIKit
import Foundation

class OpenAIVisionService {
    private let apiKey = "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" // Store securely as shown previously
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    func analyzeImage(image: UIImage, prompt: String) async throws -> String {
        // Convert image to base64
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            throw NSError(domain: "ImageProcessingError", code: 0)
        }
        
        // Prepare the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Construct the payload
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        // Send request
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return response.choices.first?.message.content ?? "No response"
    }
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}



enum APIError: Error {
    case badRequest(message: String)
    case unauthorized
    case rateLimited
    case serverError
    case decodingFailed(underlyingError: Error)
    case networkError(underlyingError: Error)
    case unknown(statusCode: Int)
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail
}

struct ErrorDetail: Codable {
    let message: String
    let type: String
    let code: String?
}
