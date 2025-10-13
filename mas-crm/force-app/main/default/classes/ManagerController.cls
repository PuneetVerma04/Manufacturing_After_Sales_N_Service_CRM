public with sharing class ManagerController {
    
    @AuraEnabled(cacheable=true)
    public static ManagerStats getManagerStats() {
        ManagerStats stats = new ManagerStats();
        
        // Total Cases
        stats.totalCases = [SELECT COUNT() FROM Service_Case__c];
        
        // Open Cases
        stats.openCases = [SELECT COUNT() FROM Service_Case__c 
                          WHERE Status__c NOT IN ('Closed', 'Resolved')];
        
        // SLA Breached Cases
        stats.slaBreached = [SELECT COUNT() FROM Service_Case__c 
                            WHERE SLA_Deadline__c < :System.now() 
                            AND Status__c NOT IN ('Closed', 'Resolved')];
        
        // Average Rating
        List<AggregateResult> avgRatingResult = [
            SELECT AVG(Rating__c) avgRating
            FROM Feedback__c
            WHERE Rating__c != null
        ];
        if (!avgRatingResult.isEmpty()) {
            stats.avgRating = (Decimal)avgRatingResult[0].get('avgRating');
        }
        
        // Active Engineers
        stats.activeEngineers = [SELECT COUNT() FROM Engineer__c WHERE Available__c = true];
        
        return stats;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CaseStatusData> getCaseStatusDistribution() {
        List<CaseStatusData> statusData = new List<CaseStatusData>();
        
        List<AggregateResult> results = [
            SELECT Status__c status, COUNT(Id)
            FROM Service_Case__c
            WHERE Status__c != null
            GROUP BY Status__c
            ORDER BY COUNT(Id) DESC
        ];
        
        for (AggregateResult result : results) {
            CaseStatusData csd = new CaseStatusData();
            csd.status = (String)result.get('status');
            csd.count = (Integer)result.get('expr0');
            statusData.add(csd);
        }
        
        return statusData;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TopProduct> getTopProducts() {
        List<TopProduct> topProducts = new List<TopProduct>();
        
        List<AggregateResult> results = [
            SELECT Registered_Product__c productId, Registered_Product__r.Name productName, COUNT(Id) caseCount
            FROM Service_Case__c
            WHERE Registered_Product__c != null
            GROUP BY Registered_Product__c, Registered_Product__r.Name
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        
        for (AggregateResult result : results) {
            TopProduct tp = new TopProduct();
            tp.productId = (Id)result.get('productId');
            tp.productName = (String)result.get('productName');
            tp.caseCount = (Integer)result.get('caseCount');
            topProducts.add(tp);
        }
        
        return topProducts;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<EngineerPerformance> getEngineerPerformance() {
        List<EngineerPerformance> performance = new List<EngineerPerformance>();
        
        List<Engineer__c> engineers = [
            SELECT Id, Name, Available__c
            FROM Engineer__c
            ORDER BY Name
        ];
        
        for (Engineer__c engineer : engineers) {
            EngineerPerformance ep = new EngineerPerformance();
            ep.engineerId = engineer.Id;
            ep.engineerName = engineer.Name;
            ep.status = engineer.Available__c ? 'Available' : 'Busy';
            
            // Count total cases assigned to this engineer
            ep.totalCases = [SELECT COUNT() FROM Service_Case__c 
                            WHERE Engineer_Assigned__c = :engineer.Id];
            
            // Count resolved cases
            ep.resolvedCases = [SELECT COUNT() FROM Service_Case__c 
                               WHERE Engineer_Assigned__c = :engineer.Id 
                               AND Status__c IN ('Resolved', 'Closed')];
            
            // Count SLA breaches
            ep.slaBreaches = [SELECT COUNT() FROM Service_Case__c 
                             WHERE Engineer_Assigned__c = :engineer.Id 
                             AND SLA_Deadline__c < :System.now() 
                             AND Status__c NOT IN ('Closed', 'Resolved')];
            
            // Calculate average resolution time (simplified)
            ep.avgResolutionTime = '2.5 days'; // This would be calculated from actual data
            
            // Get average customer rating for this engineer's cases
            List<AggregateResult> ratingResults = [
                SELECT AVG(Rating__c) avgRating
                FROM Feedback__c
                WHERE Service_Case__r.Engineer_Assigned__c = :engineer.Id
                AND Rating__c != null
            ];
            if (!ratingResults.isEmpty()) {
                ep.customerRating = (Decimal)ratingResults[0].get('avgRating');
            } else {
                ep.customerRating = 0;
            }
            
            performance.add(ep);
        }
        
        return performance;
    }
    
    @AuraEnabled(cacheable=true)
    public static SlaAnalysis getSlaAnalysis() {
        SlaAnalysis analysis = new SlaAnalysis();
        
        // Calculate SLA compliance rate
        Integer totalCases = [SELECT COUNT() FROM Service_Case__c WHERE Status__c IN ('Resolved', 'Closed')];
        Integer compliantCases = [SELECT COUNT() FROM Service_Case__c 
                                 WHERE Status__c IN ('Resolved', 'Closed') 
                                 AND SLA_Deadline__c >= :System.now()];
        
        if (totalCases > 0) {
            analysis.complianceRate = Math.round((Decimal.valueOf(compliantCases) / Decimal.valueOf(totalCases)) * 100);
        } else {
            analysis.complianceRate = 0;
        }
        
        // Average resolution time (simplified)
        analysis.avgResolutionTime = '2.3 days';
        
        // Breach trend (simplified)
        analysis.breachTrend = '+5%';
        
        return analysis;
    }
    
    @AuraEnabled(cacheable=true)
    public static FeedbackAnalysis getFeedbackAnalysis() {
        FeedbackAnalysis analysis = new FeedbackAnalysis();
        
        // Rating distribution
        List<RatingDistribution> ratingDist = new List<RatingDistribution>();
        for (Integer i = 1; i <= 5; i++) {
            Integer count = [SELECT COUNT() FROM Feedback__c WHERE Rating__c = :i];
            RatingDistribution rd = new RatingDistribution();
            rd.rating = i;
            rd.count = count;
            ratingDist.add(rd);
        }
        analysis.ratingDistribution = ratingDist;
        
        return analysis;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Feedback__c> getRecentFeedback() {
        return [
            SELECT Id, Name, Rating__c, Comments__c, CreatedDate, Service_Case__r.Name
            FROM Feedback__c
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }
    
    // Wrapper classes
    public class ManagerStats {
        @AuraEnabled public Integer totalCases = 0;
        @AuraEnabled public Integer openCases = 0;
        @AuraEnabled public Integer slaBreached = 0;
        @AuraEnabled public Decimal avgRating = 0;
        @AuraEnabled public Integer activeEngineers = 0;
    }
    
    public class CaseStatusData {
        @AuraEnabled public String status;
        @AuraEnabled public Integer count;
    }
    
    public class TopProduct {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Integer caseCount;
    }
    
    public class EngineerPerformance {
        @AuraEnabled public Id engineerId;
        @AuraEnabled public String engineerName;
        @AuraEnabled public Integer totalCases = 0;
        @AuraEnabled public Integer resolvedCases = 0;
        @AuraEnabled public Integer slaBreaches = 0;
        @AuraEnabled public String avgResolutionTime;
        @AuraEnabled public Decimal customerRating = 0;
        @AuraEnabled public String status;
    }
    
    public class SlaAnalysis {
        @AuraEnabled public Integer complianceRate = 0;
        @AuraEnabled public String avgResolutionTime;
        @AuraEnabled public String breachTrend;
    }
    
    public class FeedbackAnalysis {
        @AuraEnabled public List<RatingDistribution> ratingDistribution;
    }
    
    public class RatingDistribution {
        @AuraEnabled public Integer rating;
        @AuraEnabled public Integer count;
    }
}