public with sharing class WarrantyService {
    public class WarrantyStatus {
        @AuraEnabled public Boolean inWarranty;
        @AuraEnabled public Boolean inAmc;
        @AuraEnabled public Date warrantyExpiry;
        @AuraEnabled public Date amcExpiry;
    }

    @AuraEnabled(cacheable=true)
    public static WarrantyStatus evaluate(Id registeredProductId) {
        if (registeredProductId == null) {
            return new WarrantyStatus();
        }
        Registered_Product__c rp = [
            SELECT Id, Warranty_Expiry__c, AMC_Expiry__c
            FROM Registered_Product__c
            WHERE Id = :registeredProductId
            LIMIT 1
        ];
        return evaluate(rp);
    }

    public static WarrantyStatus evaluate(Registered_Product__c rp) {
        WarrantyStatus ws = new WarrantyStatus();
        if (rp == null) return ws;
        ws.warrantyExpiry = rp.Warranty_Expiry__c;
        ws.amcExpiry = rp.AMC_Expiry__c;
        Date today = Date.today();
        ws.inWarranty = (ws.warrantyExpiry != null && ws.warrantyExpiry >= today);
        ws.inAmc = (ws.amcExpiry != null && ws.amcExpiry >= today);
        return ws;
    }
}


