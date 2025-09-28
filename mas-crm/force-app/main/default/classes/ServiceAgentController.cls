@SuppressWarnings('PMD.ApexDoc')
@SupperssWarnings('PMD.ApexCRUDViolation')

public with sharing class ServiceAgentController {
    
    @AuraEnabled(cacheable=true)
    public static ServiceAgentStats getServiceAgentStats() {
        ServiceAgentStats stats = new ServiceAgentStats();
        
        // Total Cases
        stats.totalCases = [SELECT COUNT() FROM Service_Case__c];
        
        // Open Cases (not closed or resolved)
        stats.openCases = [SELECT COUNT() FROM Service_Case__c 
                          WHERE Status__c NOT IN ('Closed', 'Resolved')];
        
        // SLA Breached Cases
        stats.slaBreached = [SELECT COUNT() FROM Service_Case__c 
                            WHERE SLA_Deadline__c < :System.now() 
                            AND Status__c NOT IN ('Closed', 'Resolved')];
        
        // Average Rating from Feedback
        List<AggregateResult> avgRatingResult = [
            SELECT AVG(Rating__c) avgRating
            FROM Feedback__c
            WHERE Rating__c != null
        ];
        if (!avgRatingResult.isEmpty()) {
            stats.avgRating = (Decimal)avgRatingResult[0].get('avgRating');
        }
        
        return stats;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> getRecentCases() {
        return [
            SELECT Id, Name, Customer_Name__c, Subject__c, Status__c, Priority__c, CreatedDate
            FROM Service_Case__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Feedback__c> getRecentFeedback() {
        return [
            SELECT Id, Name, Rating__c, Comments__c, CreatedDate, Service_Case__r.Name
            FROM Feedback__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ProductStatus> getProductStatus() {
        List<ProductStatus> productStatusList = new List<ProductStatus>();
        
        List<Registered_Product__c> products = [ // NOPMD
            SELECT Id, Name, Product_ID__c, Warranty_Expiry__c, AMC_Expiry__c
            FROM Registered_Product__c
            ORDER BY Name
            LIMIT 20
        ];
        
        for (Registered_Product__c product : products) {
            ProductStatus ps = new ProductStatus();
            ps.productId = product.Id;
            ps.productName = product.Name;
            ps.productIdentifier = product.Product_ID__c;
            ps.warrantyExpiry = product.Warranty_Expiry__c;
            ps.amcExpiry = product.AMC_Expiry__c;
            
            // Count active cases for this product
            ps.activeCases = [SELECT COUNT() FROM Service_Case__c 
                             WHERE Registered_Product__c = :product.Id 
                             AND Status__c NOT IN ('Closed', 'Resolved')];
            
            productStatusList.add(ps);
        }
        
        return productStatusList;
    }
    
    public class ServiceAgentStats {
        @AuraEnabled public Integer totalCases = 0;
        @AuraEnabled public Integer openCases = 0;
        @AuraEnabled public Integer slaBreached = 0;
        @AuraEnabled public Decimal avgRating = 0;
    }
    
    public class ProductStatus {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productIdentifier;
        @AuraEnabled public Date warrantyExpiry;
        @AuraEnabled public Date amcExpiry;
        @AuraEnabled public Integer activeCases = 0;
    }
}
