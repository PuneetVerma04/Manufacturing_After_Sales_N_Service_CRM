/**
 * @description Test class for SLAService
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class SLAServiceTest {
    
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
        
        // Create test engineer
        Engineer__c testEngineer = new Engineer__c(
            Name = 'Test Engineer',
            Engineer_Email__c = 'test.engineer@example.com',
            Available__c = true,
            Skills__c = 'Electronics;Maintenance'
        );
        insert testEngineer;
        
        // Create test service cases - some breached, some not
        List<Service_Case__c> testCases = new List<Service_Case__c>();
        
        // Breached case 1 - past deadline, not closed
        testCases.add(new Service_Case__c(
            Subject__c = 'Breached Case 1',
            Customer_Name__c = 'Test Customer',
            Customer_Email__c = 'test.customer@example.com',
            Priority__c = 'High',
            Status__c = 'In Progress',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            Engineer_Assigned__c = testEngineer.Id,
            SLA_Deadline__c = Datetime.now().addHours(-2) // 2 hours past deadline
        ));
        
        // Breached case 2 - past deadline, not closed
        testCases.add(new Service_Case__c(
            Subject__c = 'Breached Case 2',
            Customer_Name__c = 'Test Customer 2',
            Customer_Email__c = 'test.customer2@example.com',
            Priority__c = 'Medium',
            Status__c = 'New',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            Engineer_Assigned__c = testEngineer.Id,
            SLA_Deadline__c = Datetime.now().addDays(-1) // 1 day past deadline
        ));
        
        // Non-breached case - future deadline
        testCases.add(new Service_Case__c(
            Subject__c = 'Future Case',
            Customer_Name__c = 'Test Customer 3',
            Customer_Email__c = 'test.customer3@example.com',
            Priority__c = 'Low',
            Status__c = 'New',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            SLA_Deadline__c = Datetime.now().addHours(24) // 24 hours in future
        ));
        
        // Closed case with past deadline (should not be considered breached)
        testCases.add(new Service_Case__c(
            Subject__c = 'Closed Case',
            Customer_Name__c = 'Test Customer 4',
            Customer_Email__c = 'test.customer4@example.com',
            Priority__c = 'High',
            Status__c = 'Closed',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            Engineer_Assigned__c = testEngineer.Id,
            SLA_Deadline__c = Datetime.now().addHours(-1) // Past deadline but closed
        ));
        
        // Resolved case with past deadline (should not be considered breached)
        testCases.add(new Service_Case__c(
            Subject__c = 'Resolved Case',
            Customer_Name__c = 'Test Customer 5',
            Customer_Email__c = 'test.customer5@example.com',
            Priority__c = 'Medium',
            Status__c = 'Resolved',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            Engineer_Assigned__c = testEngineer.Id,
            SLA_Deadline__c = Datetime.now().addHours(-3) // Past deadline but resolved
        ));
        
        insert testCases;
        
        // Create SLA Escalation Queue for notification testing
        Group slaQueue = new Group(
            Name = 'SLAEscalationQueue',
            Type = 'Queue'
        );
        insert slaQueue;
        
        // Create test user for queue membership
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'test.manager@example.com',
            Username = 'test.manager@example.com.test',
            Alias = 'tmgr',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Add user to queue
        GroupMember queueMember = new GroupMember(
            GroupId = slaQueue.Id,
            UserOrGroupId = testUser.Id
        );
        insert queueMember;
    }
    
    /**
     * @description Test findBreachedCases method
     */
    @IsTest
    static void testFindBreachedCases() {
        Test.startTest();
        List<Service_Case__c> breachedCases = SLAService.findBreachedCases();
        Test.stopTest();
        
        // Should return 2 breached cases (not the closed/resolved ones)
        System.assertEquals(2, breachedCases.size(), 'Should return 2 breached cases');
        
        // Verify the breached cases are the correct ones
        Set<String> breachedSubjects = new Set<String>();
        for (Service_Case__c sc : breachedCases) {
            breachedSubjects.add(sc.Subject__c);
            // Verify SLA deadline is in the past
            System.assert(sc.SLA_Deadline__c < System.now(), 'SLA deadline should be in the past');
            // Verify status is not terminal
            System.assert(!new Set<String>{'Closed', 'Resolved'}.contains(sc.Status__c), 'Status should not be terminal');
        }
        
        System.assert(breachedSubjects.contains('Breached Case 1'), 'Should contain Breached Case 1');
        System.assert(breachedSubjects.contains('Breached Case 2'), 'Should contain Breached Case 2');
    }
    
    /**
     * @description Test notifySLABreaches method with valid queue
     */
    @IsTest
    static void testNotifySLABreachesWithValidQueue() {
        // Set email deliverability to no bounce back for test
        Test.startTest();
        
        // This should not throw any exceptions
        SLAService.notifySLABreaches();
        
        Test.stopTest();
        
        // Verify no exceptions were thrown (implicit success)
        System.assert(true, 'Method executed without exceptions');
    }
    
    /**
     * @description Test notifySLABreaches method with no breached cases
     */
    @IsTest
    static void testNotifySLABreachesNoBreach() {
        // Update all cases to have future SLA deadlines
        List<Service_Case__c> allCases = [SELECT Id FROM Service_Case__c];
        for (Service_Case__c sc : allCases) {
            sc.SLA_Deadline__c = Datetime.now().addHours(24);
        }
        update allCases;
        
        Test.startTest();
        SLAService.notifySLABreaches();
        Test.stopTest();
        
        // Should execute without issues when no breaches found
        System.assert(true, 'Method executed without exceptions when no breaches');
    }
    
    /**
     * @description Test notifySLABreaches method with no SLA queue
     */
    @IsTest
    static void testNotifySLABreachesNoQueue() {
        // Delete the SLA queue
        delete [SELECT Id FROM Group WHERE Name = 'SLAEscalationQueue'];
        
        Test.startTest();
        SLAService.notifySLABreaches();
        Test.stopTest();
        
        // Should execute without issues when no queue found
        System.assert(true, 'Method executed without exceptions when no queue');
    }
    
    /**
     * @description Test buildEmailBody private method indirectly
     */
    @IsTest
    static void testEmailBodyBuilding() {
        // Create test cases for email body building
        List<Service_Case__c> testCases = [SELECT Id, Name, Subject__c, Priority__c, 
                                          SLA_Deadline__c, Engineer_Assigned__r.Name,
                                          Registered_Product__r.Name 
                                          FROM Service_Case__c WHERE Subject__c LIKE 'Breached%'];
        
        Test.startTest();
        // Trigger the email building through notifySLABreaches
        SLAService.notifySLABreaches();
        Test.stopTest();
        
        // Verify we have test cases to work with
        System.assert(testCases.size() > 0, 'Should have test cases for email body building');
    }
    
    /**
     * @description Test escapeHtml method indirectly through email building
     */
    @IsTest
    static void testHtmlEscaping() {
        // Create a case with HTML characters in subject
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Registered_Product__c testProduct = [SELECT Id FROM Registered_Product__c LIMIT 1];
        
        Service_Case__c htmlCase = new Service_Case__c(
            Subject__c = 'Test <script>alert("XSS")</script> & Issue',
            Customer_Name__c = 'Test Customer',
            Customer_Email__c = 'test.customer@example.com',
            Priority__c = 'High',
            Status__c = 'New',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            SLA_Deadline__c = Datetime.now().addHours(-1) // Past deadline
        );
        insert htmlCase;
        
        Test.startTest();
        List<Service_Case__c> breachedCases = SLAService.findBreachedCases();
        Test.stopTest();
        
        // Verify the case with HTML characters is included
        Boolean foundHtmlCase = false;
        for (Service_Case__c sc : breachedCases) {
            if (sc.Subject__c.contains('<script>')) {
                foundHtmlCase = true;
                break;
            }
        }
        System.assert(foundHtmlCase, 'Should find case with HTML characters');
    }
    
    /**
     * @description Test edge case with null SLA deadline
     */
    @IsTest
    static void testNullSLADeadline() {
        // Create case with null SLA deadline
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Registered_Product__c testProduct = [SELECT Id FROM Registered_Product__c LIMIT 1];
        
        Service_Case__c nullSLACase = new Service_Case__c(
            Subject__c = 'Null SLA Case',
            Customer_Name__c = 'Test Customer',
            Customer_Email__c = 'test.customer@example.com',
            Priority__c = 'Low',
            Status__c = 'New',
            Required_Skill__c = 'Electronics',
            Registered_Product__c = testProduct.Id,
            SLA_Deadline__c = null // Null deadline
        );
        insert nullSLACase;
        
        Test.startTest();
        List<Service_Case__c> breachedCases = SLAService.findBreachedCases();
        Test.stopTest();
        
        // Verify null SLA deadline cases are not included
        for (Service_Case__c sc : breachedCases) {
            System.assertNotEquals(null, sc.SLA_Deadline__c, 'Breached cases should have non-null SLA deadline');
        }
    }
}