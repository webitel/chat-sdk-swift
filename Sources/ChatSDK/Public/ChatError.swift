//
//  ChatError.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 20.03.2026.
//

import Foundation


public enum ChatError: Error, Equatable {

    // MARK: - Auth

    case unauthorized
    case forbidden

    // MARK: - Network

    case timeout
    case invalidURL
    case invalidResponse

    // MARK: - Client

    case encodingFailed
    case emptyMessage
    
    case cancelled
    
    case sslPinningError

    // MARK: - Server

    case notFound
    case conflict
    case internalServerError(message: String?)
    case notImplemented
    case serviceUnavailable

    // MARK: - Fallback

    case unknown(
        code: Int,
        message: String?,
        underlying: Error?
    )
}


extension ChatError {
    public static func == (lhs: ChatError, rhs: ChatError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.timeout, .timeout),
             (.notFound, .notFound),
             (.conflict, .conflict),
             (.invalidURL, .invalidURL),
             (.sslPinningError, .sslPinningError),
             (.invalidResponse, .invalidResponse),
             (.encodingFailed, .encodingFailed),
             (.notImplemented, .notImplemented),
             (.serviceUnavailable, .serviceUnavailable):
            return true

        case let (.internalServerError(lMsg), .internalServerError(rMsg)):
            return lMsg == rMsg

        case let (.unknown(lCode, lMsg, _), .unknown(rCode, rMsg, _)):
            // Compare only code and message; underlying Error isn't Equatable
            return lCode == rCode && lMsg == rMsg

        default:
            return false
        }
    }
}


extension ChatError: LocalizedError {

    public var errorDescription: String? {
        switch self {

        case .unauthorized:
            return "Unauthorized"
            
        case .cancelled:
            return "Cancelled"
                
        case .sslPinningError:
            return "ssl pinning error"

        case .forbidden:
            return "Forbidden"

        case .timeout:
            return "Request timed out"

        case .invalidURL:
            return "Invalid URL"

        case .invalidResponse:
            return "Invalid server response"

        case .encodingFailed:
            return "Failed to encode request"

        case .emptyMessage:
            return "Message must contain text or attachment"

        case .notFound:
            return "Resource not found"

        case .conflict:
            return "Conflict occurred"

        case .internalServerError(let message):
            return message ?? "Internal server error"

        case .notImplemented:
            return "Not implemented"

        case .serviceUnavailable:
            return "Service unavailable"

        case .unknown(_, let message, _):
            return message ?? "Unknown error"
        }
    }
}


public extension ChatError {
    
    static func from(
        statusCode: Int,
        message: String? = nil,
        underlying: Error? = nil
    ) -> ChatError {
        switch statusCode {
        case 401:
            return .unauthorized

        case 403:
            return .forbidden

        case 404:
            return .notFound

        case 408:
            return .timeout

        case 409:
            return .conflict

        case 500:
            return .internalServerError(message: message)

        case 501:
            return .notImplemented

        case 503:
            return .serviceUnavailable

        default:
            return .unknown(
                code: statusCode,
                message: message,
                underlying: underlying
            )
        }
    }
    
    static let unknownCode = -1
}


extension Error {
    var asChatError: ChatError {
        if let chatError = self as? ChatError {
            return chatError
        }
        
        let nsError = self as NSError
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut: return .timeout
            case NSURLErrorNotConnectedToInternet: return .serviceUnavailable
            default: break
            }
        }
        
        return ChatError.from(
            statusCode: nsError.code,
            message: nsError.localizedDescription
        )
    }
}
