//
//  SSLPinningDelegate.swift
//  ChatSDK
//
//  Created by Yurii Zhuk on 27.03.2026.
//

import Foundation
import CryptoKit


final class SSLPinningDelegate: NSObject, URLSessionDelegate {
    
    private let context: ClientContext
    private(set) var lastSSLError: ChatError?
    private let logger = SDKLogger.make("chat.sslPinning")
    
    init(context: ClientContext) {
        self.context = context
    }
    
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        lastSSLError = nil
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard !context.pinnedHashes.isEmpty else {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        
        let host = challenge.protectionSpace.host
        
        guard allowedHosts().contains(host) else {
            lastSSLError = .sslPinningError
            logger.error("sslPinningError: host not allowed: \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            lastSSLError = .sslPinningError
            logger.error("sslPinningError: SecTrustEvaluateWithError failed")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        logCertificateChain(serverTrust: serverTrust)
        let serverHashes = spkiHashes(from: serverTrust)
        
        let pinnedHashes = normalizePinnedKeys(context.pinnedHashes)
        
        if serverHashes.contains(where: { pinnedHashes.contains($0) }) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
            return
        }
        lastSSLError = .sslPinningError
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    
    private func allowedHosts() -> [String] {
        let host: String? = if #available(macOS 13.0, *) {
            if #available(iOS 16.0, *) {
                context.baseURL.host()
            } else {
                context.baseURL.host
            }
        } else {
            context.baseURL.host
        }
        
        return host.map { [$0] } ?? []
    }
    
    
    private func spkiHashes(from serverTrust: SecTrust) -> [String] {
        var hashes: [String] = []
        let certCount = SecTrustGetCertificateCount(serverTrust)
        
        for index in 0..<certCount {
            guard let cert = SecTrustGetCertificateAtIndex(serverTrust, index),
                  let publicKey = SecCertificateCopyKey(cert),
                  let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
            else {
                continue
            }
            
            guard let spkiHeader = spkiHeader(for: publicKey) else {
                continue
            }
            
            let spkiData = spkiHeader + publicKeyData
            let hash = SHA256.hash(data: spkiData)
            let base64 = Data(hash).base64EncodedString()
            hashes.append(base64)
        }
        return hashes
    }
    
    
    private func spkiHeader(for publicKey: SecKey) -> Data? {
        guard let attributes = SecKeyCopyAttributes(publicKey) as NSDictionary?,
              let keyType = attributes[kSecAttrKeyType] as? String,
              let keySize = attributes[kSecAttrKeySizeInBits] as? Int
        else {
            return nil
        }
        
        if keyType == (kSecAttrKeyTypeRSA as String) {
            switch keySize {
                case 2048:
                    return Data([
                        0x30, 0x82, 0x01, 0x22,
                        0x30, 0x0d,
                        0x06, 0x09, 0x2a, 0x86, 0x48,
                        0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,
                        0x05, 0x00,
                        0x03, 0x82, 0x01, 0x0f, 0x00
                    ])
                    
                case 4096:
                    return Data([
                        0x30, 0x82, 0x02, 0x22,
                        0x30, 0x0d,
                        0x06, 0x09, 0x2a, 0x86, 0x48,
                        0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01,
                        0x05, 0x00,
                        0x03, 0x82, 0x02, 0x0f, 0x00
                    ])
                    
                default:
                    return nil
            }
        }
        
        if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) && keySize == 256 {
            return Data([
                0x30, 0x59,
                0x30, 0x13,
                0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
                0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
                0x03, 0x42, 0x00
            ])
        }
        
        if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) && keySize == 384 {
            return Data([
                0x30, 0x76,
                0x30, 0x10,
                0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
                0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22,
                0x03, 0x62, 0x00
            ])
        }
        
        return nil
    }
    
    
    private func logCertificateChain(serverTrust: SecTrust) {
        let count = SecTrustGetCertificateCount(serverTrust)
        
        for index in 0..<count {

            guard let cert = SecTrustGetCertificateAtIndex(serverTrust, index),
                  let publicKey = SecCertificateCopyKey(cert),
                  let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?,
                  let header = spkiHeader(for: publicKey)
            else { continue }
            
            let spki = header + keyData
            let hash = Data(SHA256.hash(data: spki)).base64EncodedString()
            let subject = SecCertificateCopySubjectSummary(cert) as String? ?? "Unknown"
            
            logger.debug("sha256/\(hash): \(subject)")
        }
    }
    
    
    private func normalizePinnedKeys(_ pins: [String]) -> Set<String> {
        return Set(
            pins.compactMap { pin in
                var value = pin
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if value.hasPrefix("sha256/") {
                    value.removeFirst("sha256/".count)
                }
                
                value = value.trimmingCharacters(in: .whitespaces)
                
                guard Data(base64Encoded: value) != nil else {
                    logger.error("Invalid pin format: \(pin)")
                    return nil
                }
                
                return value
            }
        )
    }
}
