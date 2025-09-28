@SuppressWarnings('PMD.ApexCRUDViolation')

public with sharing class CustomerPortalController {

    // ---------------- Helper Methods ----------------
    private static User getCurrentUser() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    private static Contact getCurrentUserContact() {
        User u = getCurrentUser();
        if (u.ContactId != null) {
            return [SELECT Id, Name, Email FROM Contact WHERE Id = :u.ContactId LIMIT 1];
        }
        return null;
    }

    // ---------------- LWC Methods ----------------

    // Get logged-in user's Contact
    @AuraEnabled(cacheable=true)
    public static Contact getLoggedInUserContact() {
        return getCurrentUserContact();
    }

    // Get products owned by logged-in user (via ContactId)
    @AuraEnabled(cacheable=true)
    public static List<Registered_Product__c> getMyRegisteredProducts() {
        Contact c = getCurrentUserContact();
        if (c == null) return new List<Registered_Product__c>();

        return [
            SELECT Id, Name, Product_ID__c, Purchase_Date__c, Warranty_Expiry__c, AMC_Expiry__c
            FROM Registered_Product__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY Name
            LIMIT 100
        ];
    }

    @AuraEnabled
public static Id createRegisteredProduct(Registered_Product__c registeredProduct) {
    try {
        // Set OwnerId to current user if not provided
        if (registeredProduct.OwnerId == null) {
            registeredProduct.OwnerId = UserInfo.getUserId();
        }
        insert registeredProduct;
        return registeredProduct.Id;
    } catch (DmlException e) {
        throw new AuraHandledException('Error creating product: ' + e.getMessage());
    }
}

    // Check warranty status for a product
    @AuraEnabled
    public static WarrantyService.WarrantyStatus checkWarrantyStatus(String productId) {
        if (String.isBlank(productId)) {
            throw new AuraHandledException('Product ID is required');
        }

        Registered_Product__c product;
        try {
            Id recordId = Id.valueOf(productId);
            product = [SELECT Id, OwnerId
                       FROM Registered_Product__c
                       WHERE Id = :recordId AND OwnerId = :UserInfo.getUserId()
                       LIMIT 1];
        } catch (Exception e) {
            product = [SELECT Id, OwnerId
                       FROM Registered_Product__c
                       WHERE Product_ID__c = :productId AND OwnerId = :UserInfo.getUserId()
                       LIMIT 1];
        }

        if (product == null) {
            throw new AuraHandledException('Product not found or access denied.');
        }

        return WarrantyService.evaluate(product.Id);
    }

    // Create a new service request
    @AuraEnabled
    public static String createServiceRequest(String customerName, String customerEmail,
                                              String subject, String priority,
                                              String registeredProductId, String description) {
        if (String.isBlank(customerName) || String.isBlank(customerEmail) ||
            String.isBlank(subject) || String.isBlank(priority) ||
            String.isBlank(registeredProductId)) {
            throw new AuraHandledException('All required fields must be filled.');
        }

        Service_Case__c serviceCase = new Service_Case__c(
            Customer_Name__c = customerName,
            Customer_Email__c = customerEmail,
            Subject__c = subject,
            Priority__c = priority,
            Registered_Product__c = registeredProductId,
            Status__c = 'New',
            Description__c = description
        );

        insert serviceCase;
        return serviceCase.Id;
    }

    // Get products visible to the logged-in user
    @AuraEnabled(cacheable=true)
    public static List<Registered_Product__c> getMyProducts() {
        Contact c = getCurrentUserContact();
        if (c == null) return new List<Registered_Product__c>();

        return [
            SELECT Id, Name, Product_ID__c, Purchase_Date__c, Warranty_Expiry__c, AMC_Expiry__c
            FROM Registered_Product__c
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY Name
            LIMIT 50
        ];
    }

    // Get product catalog (Product2)
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductCatalog() { // NOPMD
        return [
            SELECT Id, Name, ProductCode, Family
            FROM Product2
            WHERE IsActive = true
            ORDER BY Name
            LIMIT 100
        ];
    }


    // Get service cases for logged-in user
    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> getMyCases() {
        Contact c = getCurrentUserContact();
        if (c == null) return new List<Service_Case__c>();

        return [
            SELECT Id, Name, Subject__c, Status__c, Priority__c, CreatedDate,
                   Engineer_Assigned__r.Name, Registered_Product__r.Name
            FROM Service_Case__c
            WHERE Customer_Email__c = :c.Email
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    // Get recent service cases for logged-in user
    @AuraEnabled(cacheable=true)
    public static List<Service_Case__c> getMyRecentCases() {
        Contact c = getCurrentUserContact();
        if (c == null) return new List<Service_Case__c>();

        return [
            SELECT Id, Name, Subject__c, Status__c, Priority__c, CreatedDate
            FROM Service_Case__c
            WHERE Customer_Email__c = :c.Email
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
    }
}
