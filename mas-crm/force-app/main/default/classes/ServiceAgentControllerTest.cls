/**
 * @description Test class for ServiceAgentController
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class ServiceAgentControllerTest {
    
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
        
        // Create test registered products
        List<Registered_Product__c> testProducts = new List<Registered_Product__c>();
        for (Integer i = 1; i <= 3; i++) {
            testProducts.add(new Registered_Product__c(
                Name = 'Test Product ' + i,
                Serial_Number__c = 'TEST-00' + i,
                Purchase_Date__c = Date.today().addDays(-100),
                Warranty_Expiry__c = i == 1 ? Date.today().addDays(-10) : Date.today().addDays(265), // First product warranty expired
                AMC_Expiry__c = Date.today().addDays(365),
                Contact__c = testContact.Id
            ));
        }
        insert testProducts;
        
        // Create test service cases
        List<Service_Case__c> testCases = new List<Service_Case__c>();
        for (Integer i = 0; i < testProducts.size(); i++) {
            testCases.add(new Service_Case__c(
                Subject__c = 'Test Issue ' + (i + 1),
                Customer_Name__c = 'Test Customer',
                Customer_Email__c = 'test.customer@example.com',
                Priority__c = i == 0 ? 'High' : 'Medium',
                Status__c = i == 0 ? 'Resolved' : 'New',
                Required_Skill__c = 'Electronics',
                Registered_Product__c = testProducts[i].Id,
                SLA_Deadline__c = i == 0 ? Datetime.now().addHours(-2) : Datetime.now().addHours(24) // First case breached SLA
            ));
        }
        insert testCases;
        
        // Create test feedback for resolved case
        Feedback__c testFeedback = new Feedback__c(
            Service_Case__c = testCases[0].Id,
            Rating__c = 4,
            Comments__c = 'Good service, resolved quickly'
        );
        insert testFeedback;
    }
    
    /**
     * @description Test getServiceAgentStats method
     */
    @IsTest
    static void testGetServiceAgentStats() {
        Test.startTest();
        ServiceAgentController.ServiceAgentStats result = ServiceAgentController.getServiceAgentStats();
        Test.stopTest();
        
        System.assertEquals(3, result.totalCases, 'Should return correct total cases count');
        System.assertEquals(2, result.openCases, 'Should return correct open cases count');
        System.assertEquals(1, result.slaBreached, 'Should return correct SLA breached count');
        System.assertEquals(4, result.avgRating, 'Should return correct average rating');
    }
    
    /**
     * @description Test getRecentCases method
     */
    @IsTest
    static void testGetRecentCases() {
        Test.startTest();
        List<Service_Case__c> results = ServiceAgentController.getRecentCases();
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return all test cases');
        System.assertEquals('Test Issue 3', results[0].Subject__c, 'Should be ordered by creation date desc');
    }
    
    /**
     * @description Test getRecentFeedback method
     */
    @IsTest
    static void testGetRecentFeedback() {
        Test.startTest();
        List<Feedback__c> results = ServiceAgentController.getRecentFeedback();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one feedback record');
        System.assertEquals(4, results[0].Rating__c, 'Should return correct rating');
        System.assertEquals('Good service, resolved quickly', results[0].Comments__c, 'Should return correct comments');
    }
    
    /**
     * @description Test getProductStatus method
     */
    @IsTest
    static void testGetProductStatus() {
        Test.startTest();
        List<ServiceAgentController.ProductStatus> results = ServiceAgentController.getProductStatus();
        Test.stopTest();
        
        System.assertEquals(3, results.size(), 'Should return all test products');
        
        // Verify product status structure
        ServiceAgentController.ProductStatus firstProduct = results[0];
        System.assertNotEquals(null, firstProduct.productId, 'Product ID should not be null');
        System.assertNotEquals(null, firstProduct.productName, 'Product name should not be null');
        System.assertNotEquals(null, firstProduct.productIdentifier, 'Product identifier should not be null');
        System.assertEquals(1, firstProduct.activeCases, 'Should have correct active cases count');
    }
    
    /**
     * @description Test ServiceAgentStats wrapper class
     */
    @IsTest
    static void testServiceAgentStatsWrapper() {
        ServiceAgentController.ServiceAgentStats stats = new ServiceAgentController.ServiceAgentStats();
        stats.totalCases = 10;
        stats.openCases = 5;
        stats.slaBreached = 2;
        stats.avgRating = 4.5;
        
        System.assertEquals(10, stats.totalCases, 'Total cases should be set correctly');
        System.assertEquals(5, stats.openCases, 'Open cases should be set correctly');
        System.assertEquals(2, stats.slaBreached, 'SLA breached should be set correctly');
        System.assertEquals(4.5, stats.avgRating, 'Average rating should be set correctly');
    }
    
    /**
     * @description Test ProductStatus wrapper class
     */
    @IsTest
    static void testProductStatusWrapper() {
        ServiceAgentController.ProductStatus productStatus = new ServiceAgentController.ProductStatus();
        productStatus.productId = 'a03XX000000001';
        productStatus.productName = 'Test Product';
        productStatus.productIdentifier = 'TEST-001';
        productStatus.warrantyExpiry = Date.today().addDays(365);
        productStatus.amcExpiry = Date.today().addDays(365);
        productStatus.activeCases = 3;
        
        System.assertEquals('a03XX000000001', productStatus.productId, 'Product ID should be set correctly');
        System.assertEquals('Test Product', productStatus.productName, 'Product name should be set correctly');
        System.assertEquals('TEST-001', productStatus.productIdentifier, 'Product identifier should be set correctly');
        System.assertEquals(3, productStatus.activeCases, 'Active cases should be set correctly');
    }
    
    /**
     * @description Test edge case with no data
     */
    @IsTest
    static void testNoDataScenario() {
        // Delete all test data
        delete [SELECT Id FROM Feedback__c];
        delete [SELECT Id FROM Service_Case__c];
        delete [SELECT Id FROM Registered_Product__c];
        delete [SELECT Id FROM Contact];
        
        Test.startTest();
        ServiceAgentController.ServiceAgentStats stats = ServiceAgentController.getServiceAgentStats();
        List<Service_Case__c> cases = ServiceAgentController.getRecentCases();
        List<Feedback__c> feedback = ServiceAgentController.getRecentFeedback();
        List<ServiceAgentController.ProductStatus> products = ServiceAgentController.getProductStatus();
        Test.stopTest();
        
        System.assertEquals(0, stats.totalCases, 'Should return zero total cases');
        System.assertEquals(0, stats.openCases, 'Should return zero open cases');
        System.assertEquals(0, stats.slaBreached, 'Should return zero SLA breached');
        System.assertEquals(0, stats.avgRating, 'Should return zero average rating');
        System.assertEquals(0, cases.size(), 'Should return empty cases list');
        System.assertEquals(0, feedback.size(), 'Should return empty feedback list');
        System.assertEquals(0, products.size(), 'Should return empty products list');
    }
}
