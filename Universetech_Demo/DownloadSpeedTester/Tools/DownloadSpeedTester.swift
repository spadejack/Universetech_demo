//
//  Untitled.swift
//  Universetech_Demo
//
//  Created by Jack Din on 2025/5/15.
//

import Foundation

public protocol DownloadSpeedTestable {
    func start(completed: @escaping (Bool) -> Void)
    func getResult() -> [DownLoadResultModel]
}

public class DownloadSpeedTesterImpl: DownloadSpeedTestable {
    private let domains: [String]
    private var results: [DownLoadResultModel] = []
    private let imageUrl = "/test-img"
    
    public init(domains: [String] = []) {
        self.domains = domains
    }
    
    public func start(completed: @escaping (Bool) -> Void) {
        var tempResults: [DownLoadResultModel] = []
        let group = DispatchGroup()
        var encounteredErrors = false
        
        for domain in domains {
            group.enter()
            downloadImg(domain: domain) { result in
                if let model = result {
                    tempResults.append(model)
                } else {
                    encounteredErrors = true
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.setResult(in: tempResults) {
                completed(!encounteredErrors)
            }
        }
    }
    
    private func downloadImg(domain: String, completed: @escaping (DownLoadResultModel?) -> Void) {
        guard let url = URL(string: "https://\(domain)\(imageUrl)") else {
            completed(nil)
            return
        }
        
        let startTime = Date()
        
        let task = URLSession.shared.dataTask(with: url) { _, _, error in
            let duration = Date().timeIntervalSince(startTime) * 1000
            if let error = error {
                print("\(domain) Download failed: \(error.localizedDescription)")
                completed(nil)
                return
            } else {
                let model = DownLoadResultModel(domain: domain, duration: duration)
                completed(model)
            }
        }
        
        task.resume()
    }
    
    private func setResult(in resultList: [DownLoadResultModel], completed: @escaping () -> Void) {
        results = resultList.sorted { $0.duration < $1.duration }
        completed()
    }
    
    public func getResult() -> [DownLoadResultModel] {
        return results
    }
}
