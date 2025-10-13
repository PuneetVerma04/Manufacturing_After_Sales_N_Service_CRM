/**
 * @description Test class for WarrantyService
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class WarrantyServiceTest {
    
    /**
     * @description Test data factory method to create test records
     */
    @TestSetup
    static void makeData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Customer',
            Email = 'test.customer@example.com'
        );
        insert testContact;
        
        // Create test registered products with different warranty/AMC statuses
        List<Registered_Product__c> testProducts = new List<Registered_Product__c>();
        
        // Product 1: Both warranty and AMC active
        testProducts.add(new Registered_Product__c(
            Name = 'Active Warranty Product',
            Serial_Name__c = 'AWP-001',
            Purchase_Date__c = Date.today().addDays(-100),
            Warranty_Expiry__c = Date.today().addDays(100), // Active warranty
            AMC_Expiry__c = Date.today().addDays(200), // Active AMC
            Contact__c = testContact.Id
        ));
        
        // Product 2: Warranty expired, AMC active
        testProducts.add(new Registered_Product__c(
            Name = 'Expired Warranty Product',
            Serial_Name__c = 'EWP-002',
            Purchase_Date__c = Date.today().addDays(-500),
            Warranty_Expiry__c = Date.today().addDays(-50), // Expired warranty
            AMC_Expiry__c = Date.today().addDays(100), // Active AMC
            Contact__c = testContact.Id
        ));
        
        // Product 3: Both warranty and AMC expired
        testProducts.add(new Registered_Product__c(
            Name = 'Fully Expired Product',
            Serial_Name__c = 'FEP-003',
            Purchase_Date__c = Date.today().addDays(-800),
            Warranty_Expiry__c = Date.today().addDays(-200), // Expired warranty
            AMC_Expiry__c = Date.today().addDays(-100), // Expired AMC
            Contact__c = testContact.Id
        ));
        
        // Product 4: Null warranty and AMC dates
        testProducts.add(new Registered_Product__c(
            Name = 'No Coverage Product',
            Serial_Name__c = 'NCP-004',
            Purchase_Date__c = Date.today().addDays(-100),
            Warranty_Expiry__c = null, // No warranty
            AMC_Expiry__c = null, // No AMC
            Contact__c = testContact.Id
        ));
        
        // Product 5: Warranty active, no AMC
        testProducts.add(new Registered_Product__c(
            Name = 'Warranty Only Product',
            Serial_Name__c = 'WOP-005',
            Purchase_Date__c = Date.today().addDays(-50),
            Warranty_Expiry__c = Date.today().addDays(150), // Active warranty
            AMC_Expiry__c = null, // No AMC
            Contact__c = testContact.Id
        ));
        
        insert testProducts;
    }
    
    /**
     * @description Test evaluate method with product ID - active warranty and AMC
     */
    @IsTest
    static void testEvaluateWithIdActiveWarrantyAndAMC() {
        Registered_Product__c product = [SELECT Id FROM Registered_Product__c WHERE Serial_Name__c = 'AWP-001' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.inWarranty, 'Product should be in warranty');
        System.assertEquals(true, result.inAmc, 'Product should be in AMC');
        System.assertNotEquals(null, result.warrantyExpiry, 'Warranty expiry should not be null');
        System.assertNotEquals(null, result.amcExpiry, 'AMC expiry should not be null');
    }
    
    /**
     * @description Test evaluate method with product ID - expired warranty, active AMC
     */
    @IsTest
    static void testEvaluateWithIdExpiredWarrantyActiveAMC() {
        Registered_Product__c product = [SELECT Id FROM Registered_Product__c WHERE Serial_Name__c = 'EWP-002' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.inWarranty, 'Product should not be in warranty');
        System.assertEquals(true, result.inAmc, 'Product should be in AMC');
        System.assertNotEquals(null, result.warrantyExpiry, 'Warranty expiry should not be null');
        System.assertNotEquals(null, result.amcExpiry, 'AMC expiry should not be null');
    }
    
    /**
     * @description Test evaluate method with product ID - both expired
     */
    @IsTest
    static void testEvaluateWithIdBothExpired() {
        Registered_Product__c product = [SELECT Id FROM Registered_Product__c WHERE Serial_Name__c = 'FEP-003' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.inWarranty, 'Product should not be in warranty');
        System.assertEquals(false, result.inAmc, 'Product should not be in AMC');
        System.assertNotEquals(null, result.warrantyExpiry, 'Warranty expiry should not be null');
        System.assertNotEquals(null, result.amcExpiry, 'AMC expiry should not be null');
    }
    
    /**
     * @description Test evaluate method with product ID - null coverage
     */
    @IsTest
    static void testEvaluateWithIdNullCoverage() {
        Registered_Product__c product = [SELECT Id FROM Registered_Product__c WHERE Serial_Name__c = 'NCP-004' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.inWarranty, 'Product should not be in warranty when null');
        System.assertEquals(false, result.inAmc, 'Product should not be in AMC when null');
        System.assertEquals(null, result.warrantyExpiry, 'Warranty expiry should be null');
        System.assertEquals(null, result.amcExpiry, 'AMC expiry should be null');
    }
    
    /**
     * @description Test evaluate method with product ID - warranty only
     */
    @IsTest
    static void testEvaluateWithIdWarrantyOnly() {
        Registered_Product__c product = [SELECT Id FROM Registered_Product__c WHERE Serial_Name__c = 'WOP-005' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.inWarranty, 'Product should be in warranty');
        System.assertEquals(false, result.inAmc, 'Product should not be in AMC when null');
        System.assertNotEquals(null, result.warrantyExpiry, 'Warranty expiry should not be null');
        System.assertEquals(null, result.amcExpiry, 'AMC expiry should be null');
    }
    
    /**
     * @description Test evaluate method with null product ID
     */
    @IsTest
    static void testEvaluateWithNullId() {
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate((Id)null);
        Test.stopTest();
        
        System.assertEquals(false, result.inWarranty, 'Should return false for warranty when null ID');
        System.assertEquals(false, result.inAmc, 'Should return false for AMC when null ID');
        System.assertEquals(null, result.warrantyExpiry, 'Warranty expiry should be null');
        System.assertEquals(null, result.amcExpiry, 'AMC expiry should be null');
    }
    
    /**
     * @description Test evaluate method with product record - active coverage
     */
    @IsTest
    static void testEvaluateWithRecordActiveCoverage() {
        Registered_Product__c product = [SELECT Id, Warranty_Expiry__c, AMC_Expiry__c 
                                        FROM Registered_Product__c 
                                        WHERE Serial_Name__c = 'AWP-001' LIMIT 1];
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(product);
        Test.stopTest();
        
        System.assertEquals(true, result.inWarranty, 'Product should be in warranty');
        System.assertEquals(true, result.inAmc, 'Product should be in AMC');
        System.assertEquals(product.Warranty_Expiry__c, result.warrantyExpiry, 'Warranty expiry should match');
        System.assertEquals(product.AMC_Expiry__c, result.amcExpiry, 'AMC expiry should match');
    }
    
    /**
     * @description Test evaluate method with null product record
     */
    @IsTest
    static void testEvaluateWithNullRecord() {
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate((Registered_Product__c)null);
        Test.stopTest();
        
        System.assertEquals(false, result.inWarranty, 'Should return false for warranty when null record');
        System.assertEquals(false, result.inAmc, 'Should return false for AMC when null record');
        System.assertEquals(null, result.warrantyExpiry, 'Warranty expiry should be null');
        System.assertEquals(null, result.amcExpiry, 'AMC expiry should be null');
    }
    
    /**
     * @description Test WarrantyStatus wrapper class initialization
     */
    @IsTest
    static void testWarrantyStatusWrapper() {
        WarrantyService.WarrantyStatus status = new WarrantyService.WarrantyStatus();
        
        // Verify default values
        System.assertEquals(false, status.inWarranty, 'Default warranty status should be false');
        System.assertEquals(false, status.inAmc, 'Default AMC status should be false');
        System.assertEquals(null, status.warrantyExpiry, 'Default warranty expiry should be null');
        System.assertEquals(null, status.amcExpiry, 'Default AMC expiry should be null');
        
        // Test setting values
        status.inWarranty = true;
        status.inAmc = true;
        status.warrantyExpiry = Date.today().addDays(100);
        status.amcExpiry = Date.today().addDays(200);
        
        System.assertEquals(true, status.inWarranty, 'Warranty status should be settable');
        System.assertEquals(true, status.inAmc, 'AMC status should be settable');
        System.assertNotEquals(null, status.warrantyExpiry, 'Warranty expiry should be settable');
        System.assertNotEquals(null, status.amcExpiry, 'AMC expiry should be settable');
    }
    
    /**
     * @description Test edge case with warranty expiring today
     */
    @IsTest
    static void testWarrantyExpiringToday() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Registered_Product__c todayProduct = new Registered_Product__c(
            Name = 'Expiring Today Product',
            Serial_Name__c = 'ETP-006',
            Purchase_Date__c = Date.today().addDays(-365),
            Warranty_Expiry__c = Date.today(), // Expires today
            AMC_Expiry__c = Date.today(), // Expires today
            Contact__c = testContact.Id
        );
        insert todayProduct;
        
        Test.startTest();
        WarrantyService.WarrantyStatus result = WarrantyService.evaluate(todayProduct.Id);
        Test.stopTest();
        
        // Products expiring today should still be considered active
        System.assertEquals(true, result.inWarranty, 'Product expiring today should still be in warranty');
        System.assertEquals(true, result.inAmc, 'Product expiring today should still be in AMC');
    }
    
    /**
     * @description Test invalid product ID handling
     */
    @IsTest
    static void testInvalidProductId() {
        // Generate a fake ID that doesn't exist
        Id fakeId = '001000000000000'; // Invalid but properly formatted ID
        
        Test.startTest();
        try {
            WarrantyService.WarrantyStatus result = WarrantyService.evaluate(fakeId);
            System.assert(false, 'Should have thrown an exception for invalid ID');
        } catch (Exception e) {
            // Expected behavior - SOQL should fail for non-existent ID
            System.assert(true, 'Expected exception for invalid product ID');
        }
        Test.stopTest();
    }
}