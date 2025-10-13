/**
 * @description Test class for EngineerDashboardController
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class EngineerDashboardControllerTest {
    
    /**
     * @description Test data factory method to create test records
     */
    @TestSetup
    static void makeData() {
        // Create test engineer
        Engineer__c testEngineer = new Engineer__c(
            Name = 'Test Engineer',
            Engineer_Email__c = 'test.engineer@example.com',
            Available__c = true,
            Skills__c = 'Electronics;Maintenance'
        );
        insert testEngineer;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Customer',
            Email = 'test.customer@example.com'
        );
        insert testContact;
        
        // Create test registered product
        Registered_Product__c testProduct = new Registered_Product__c(
            Name = 'Test Product',
            Serial_Name__c = 'TEST-001',
            Purchase_Date__c = Date.today().addDays(-100),
            Warranty_Expiry__c = Date.today().addDays(265),
            AMC_Expiry__c = Date.today().addDays(365),
            Contact__c = testContact.Id
        );
        insert testProduct;
        
        // Create test service case
        Service_Case__c testCase = new Service_Case__c(
            Subject__c = 'Test Issue',
            Customer_Name__c = 'Test Customer',
            Customer_Email__c = 'test.customer@example.com',
            Priority__c = 'High',
            Status__c = 'Engineer Dispatched',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            Engineer_Assigned__c = testEngineer.Id,
            SLA_Deadline__c = Datetime.now().addHours(24)
        );
        insert testCase;
        
        // Create test dispatch
        Dispatch__c testDispatch = new Dispatch__c(
            Name = 'DISP-001',
            Service_Case__c = testCase.Id,
            Engineer_Assigned__c = testEngineer.Id,
            Service_Date__c = Datetime.now()
        );
        insert testDispatch;
    }
    
    /**
     * @description Test getEngineerInfo method
     */
    @IsTest
    static void testGetEngineerInfo() {
        Test.startTest();
        Engineer__c result = EngineerDashboardController.getEngineerInfo();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Engineer info should be returned');
        System.assertEquals('Test Engineer', result.Name, 'Engineer name should match');
        System.assertEquals('test.engineer@example.com', result.Engineer_Email__c, 'Engineer email should match');
    }
    
    /**
     * @description Test getAssignedJobs method
     */
    @IsTest
    static void testGetAssignedJobs() {
        Test.startTest();
        List<Service_Case__c> results = EngineerDashboardController.getAssignedJobs();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one assigned job');
        System.assertEquals('Test Issue', results[0].Subject__c, 'Subject should match');
        System.assertEquals('Engineer Dispatched', results[0].Status__c, 'Status should be Engineer Dispatched');
    }
    
    /**
     * @description Test getDispatchJobs method
     */
    @IsTest
    static void testGetDispatchJobs() {
        Test.startTest();
        List<Dispatch__c> results = EngineerDashboardController.getDispatchJobs();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one dispatch job');
        System.assertEquals('DISP-001', results[0].Name, 'Dispatch name should match');
    }
    
    /**
     * @description Test successful status update from Engineer Dispatched to In Progress
     */
    @IsTest
    static void testUpdateJobStatusSuccess() {
        Service_Case__c testCase = [SELECT Id FROM Service_Case__c LIMIT 1];
        
        Test.startTest();
        String result = EngineerDashboardController.updateJobStatus(
            testCase.Id, 
            'In Progress', 
            'Started working on the issue'
        );
        Test.stopTest();
        
        System.assertEquals('Case status updated to In Progress', result, 'Success message should be returned');
        
        // Verify the update
        Service_Case__c updatedCase = [SELECT Status__c, Engineer_Feedback__c FROM Service_Case__c WHERE Id = :testCase.Id];
        System.assertEquals('In Progress', updatedCase.Status__c, 'Status should be updated');
        System.assertEquals('Started working on the issue', updatedCase.Engineer_Feedback__c, 'Feedback should be added');
    }
    
    /**
     * @description Test invalid status transition
     */
    @IsTest
    static void testUpdateJobStatusInvalidTransition() {
        Service_Case__c testCase = [SELECT Id FROM Service_Case__c LIMIT 1];
        
        Test.startTest();
        try {
            EngineerDashboardController.updateJobStatus(testCase.Id, 'Closed', 'Invalid transition');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status change'), 'Should contain invalid status message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test status update with additional comments
     */
    @IsTest
    static void testUpdateJobStatusWithAdditionalComments() {
        Service_Case__c testCase = [SELECT Id FROM Service_Case__c LIMIT 1];
        
        // First update
        EngineerDashboardController.updateJobStatus(testCase.Id, 'In Progress', 'Initial comment');
        
        // Second update
        Test.startTest();
        String result = EngineerDashboardController.updateJobStatus(testCase.Id, 'Resolved', 'Issue resolved');
        Test.stopTest();
        
        System.assertEquals('Case status updated to Resolved', result, 'Success message should be returned');
        
        // Verify feedback concatenation
        Service_Case__c updatedCase = [SELECT Engineer_Feedback__c FROM Service_Case__c WHERE Id = :testCase.Id];
        System.assert(updatedCase.Engineer_Feedback__c.contains('Initial comment'), 'Should contain initial comment');
        System.assert(updatedCase.Engineer_Feedback__c.contains('Issue resolved'), 'Should contain new comment');
    }
    
    /**
     * @description Test updateJobStatus with invalid case ID
     */
    @IsTest
    static void testUpdateJobStatusInvalidCaseId() {
        Test.startTest();
        try {
            EngineerDashboardController.updateJobStatus('invalid_id', 'In Progress', 'Test');
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error updating job status'), 'Should contain error message');
        }
        Test.stopTest();
    }
}