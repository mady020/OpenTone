import Foundation

struct Report: Identifiable, Codable, Sendable {
    let id: String                          
    let reporterUserID: String                  
    let reportedEntityID: String            
    let entityType: ReportedEntityType      
    let reason: ReportReason   
    let reasonDetails: String?             
    let message: String?                    
    let timestamp: Date                     
}
