trigger RegisteredProductTrigger on Registered_Product__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Service_Case__c> casesToInsert = new List<Service_Case__c>();
        
        for (Registered_Product__c rp : Trigger.new) {
            Registered_Product__c oldRp = Trigger.oldMap.get(rp.Id);
            
            // Check if Defective__c changed from false/null to true
            if ((oldRp.Defective__c == false || oldRp.Defective__c == null) && rp.Defective__c == true) {
                Service_Case__c sc = new Service_Case__c();
                sc.Subject__c = 'Defective product reported - Auto-generated when product marked as Defective.';
                sc.Status__c = 'New';
                sc.Priority__c = 'High';
                sc.Registered_Product__c = rp.Id;

                // Set required customer fields
                if (rp.Contact__c != null) {
                    Contact c = [SELECT Id, Name, Email FROM Contact WHERE Id = :rp.Contact__c LIMIT 1];
                    sc.Customer_Name__c = c.Name;
                    sc.Customer_Email__c = c.Email;
                }

                casesToInsert.add(sc);
            }
        }
        
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }
    }
}
