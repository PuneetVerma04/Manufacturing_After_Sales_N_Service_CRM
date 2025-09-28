public with sharing class ReportingService {
    public class ProductCaseCount {
        @AuraEnabled public Id registeredProductId;
        @AuraEnabled public Integer caseCount;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCaseCount> top5ProductsByServiceRequests() {
        List<AggregateResult> rows = [
            SELECT Registered_Product__c rp, COUNT(Id) cnt
            FROM Service_Case__c
            WHERE Registered_Product__c != null
            GROUP BY Registered_Product__c
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        List<ProductCaseCount> out = new List<ProductCaseCount>();
        for (AggregateResult ar : rows) {
            ProductCaseCount p = new ProductCaseCount();
            p.registeredProductId = (Id) ar.get('rp');
            p.caseCount = (Integer) ar.get('cnt');
            out.add(p);
        }
        return out;
    }

    public class EngineerBreachCount {
        @AuraEnabled public Id engineerId;
        @AuraEnabled public Integer breachCount;
    }

    @AuraEnabled(cacheable=true)
    public static List<EngineerBreachCount> engineersWithMostSlaBreaches() {
        // Breach heuristic: SLA_Deadline__c in the past and Status__c != 'Closed'
        List<AggregateResult> rows = [
            SELECT Engineer_Assigned__c eng, COUNT(Id) cnt
            FROM Service_Case__c
            WHERE Engineer_Assigned__c != null AND SLA_Deadline__c != null
              AND SLA_Deadline__c < :System.now() AND Status__c != 'Closed'
            GROUP BY Engineer_Assigned__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        List<EngineerBreachCount> out = new List<EngineerBreachCount>();
        for (AggregateResult ar : rows) {
            EngineerBreachCount e = new EngineerBreachCount();
            e.engineerId = (Id) ar.get('eng');
            e.breachCount = (Integer) ar.get('cnt');
            out.add(e);
        }
        return out;
    }
}


