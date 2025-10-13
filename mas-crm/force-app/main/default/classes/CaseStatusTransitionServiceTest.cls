/**
 * @description Test class for CaseStatusTransitionService
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class CaseStatusTransitionServiceTest {
    
    /**
     * @description Test isValidTransition method with valid transitions
     */
    @IsTest
    static void testIsValidTransitionValid() {
        // Clear cache to ensure fresh data
        CaseStatusTransitionService.clearCache();
        
        Test.startTest();
        Boolean result1 = CaseStatusTransitionService.isValidTransition('Engineer Dispatched', 'In Progress');
        Boolean result2 = CaseStatusTransitionService.isValidTransition('In Progress', 'Resolved');
        Test.stopTest();
        
        System.assertEquals(true, result1, 'Engineer Dispatched to In Progress should be valid');
        System.assertEquals(true, result2, 'In Progress to Resolved should be valid');
    }
    
    /**
     * @description Test isValidTransition method with invalid transitions
     */
    @IsTest
    static void testIsValidTransitionInvalid() {
        Test.startTest();
        Boolean result1 = CaseStatusTransitionService.isValidTransition('Engineer Dispatched', 'Closed');
        Boolean result2 = CaseStatusTransitionService.isValidTransition('New', 'Resolved');
        Boolean result3 = CaseStatusTransitionService.isValidTransition('In Progress', 'Engineer Dispatched');
        Test.stopTest();
        
        System.assertEquals(false, result1, 'Engineer Dispatched to Closed should be invalid');
        System.assertEquals(false, result2, 'New to Resolved should be invalid');
        System.assertEquals(false, result3, 'In Progress to Engineer Dispatched should be invalid');
    }
    
    /**
     * @description Test isValidTransition method with null/blank values
     */
    @IsTest
    static void testIsValidTransitionNullBlank() {
        Test.startTest();
        Boolean result1 = CaseStatusTransitionService.isValidTransition(null, 'In Progress');
        Boolean result2 = CaseStatusTransitionService.isValidTransition('Engineer Dispatched', null);
        Boolean result3 = CaseStatusTransitionService.isValidTransition('', 'In Progress');
        Boolean result4 = CaseStatusTransitionService.isValidTransition('Engineer Dispatched', '');
        Test.stopTest();
        
        System.assertEquals(false, result1, 'Null from status should be invalid');
        System.assertEquals(false, result2, 'Null to status should be invalid');
        System.assertEquals(false, result3, 'Blank from status should be invalid');
        System.assertEquals(false, result4, 'Blank to status should be invalid');
    }
    
    /**
     * @description Test getValidNextStatuses method
     */
    @IsTest
    static void testGetValidNextStatuses() {
        Test.startTest();
        Set<String> engineerDispatchedNext = CaseStatusTransitionService.getValidNextStatuses('Engineer Dispatched');
        Set<String> inProgressNext = CaseStatusTransitionService.getValidNextStatuses('In Progress');
        Set<String> invalidNext = CaseStatusTransitionService.getValidNextStatuses('Invalid Status');
        Test.stopTest();
        
        System.assertEquals(1, engineerDispatchedNext.size(), 'Engineer Dispatched should have 1 next status');
        System.assert(engineerDispatchedNext.contains('In Progress'), 'Should contain In Progress');
        
        System.assertEquals(1, inProgressNext.size(), 'In Progress should have 1 next status');
        System.assert(inProgressNext.contains('Resolved'), 'Should contain Resolved');
        
        System.assertEquals(0, invalidNext.size(), 'Invalid status should have no next statuses');
    }
    
    /**
     * @description Test getValidNextStatuses method with null/blank values
     */
    @IsTest
    static void testGetValidNextStatusesNullBlank() {
        Test.startTest();
        Set<String> nullResult = CaseStatusTransitionService.getValidNextStatuses(null);
        Set<String> blankResult = CaseStatusTransitionService.getValidNextStatuses('');
        Test.stopTest();
        
        System.assertEquals(0, nullResult.size(), 'Null status should return empty set');
        System.assertEquals(0, blankResult.size(), 'Blank status should return empty set');
    }
    
    /**
     * @description Test getValidTransitions method and caching
     */
    @IsTest
    static void testGetValidTransitionsAndCaching() {
        // Clear cache first
        CaseStatusTransitionService.clearCache();
        
        Test.startTest();
        Map<String, Set<String>> transitions1 = CaseStatusTransitionService.getValidTransitions();
        Map<String, Set<String>> transitions2 = CaseStatusTransitionService.getValidTransitions();
        Test.stopTest();
        
        // Both calls should return the same object (cached)
        System.assertEquals(transitions1, transitions2, 'Should return cached result');
        
        // Verify structure
        System.assert(transitions1.containsKey('Engineer Dispatched'), 'Should contain Engineer Dispatched');
        System.assert(transitions1.containsKey('In Progress'), 'Should contain In Progress');
        System.assert(transitions1.get('Engineer Dispatched').contains('In Progress'), 'Should map correctly');
        System.assert(transitions1.get('In Progress').contains('Resolved'), 'Should map correctly');
    }
    
    /**
     * @description Test loadTransitionsFromMetadata method
     */
    @IsTest
    static void testLoadTransitionsFromMetadata() {
        Test.startTest();
        CaseStatusTransitionService.loadTransitionsFromMetadata();
        Map<String, Set<String>> transitions = CaseStatusTransitionService.getValidTransitions();
        Test.stopTest();
        
        System.assertNotEquals(null, transitions, 'Transitions should not be null');
        System.assert(transitions.size() >= 2, 'Should have at least 2 from statuses');
    }
    
    /**
     * @description Test clearCache method
     */
    @IsTest
    static void testClearCache() {
        // Load cache first
        CaseStatusTransitionService.getValidTransitions();
        
        Test.startTest();
        CaseStatusTransitionService.clearCache();
        // This should trigger a reload
        Map<String, Set<String>> transitions = CaseStatusTransitionService.getValidTransitions();
        Test.stopTest();
        
        System.assertNotEquals(null, transitions, 'Should reload after cache clear');
    }
    
    /**
     * @description Test getTransitionErrorMessage method
     */
    @IsTest
    static void testGetTransitionErrorMessage() {
        Test.startTest();
        String error1 = CaseStatusTransitionService.getTransitionErrorMessage('Engineer Dispatched', 'Closed');
        String error2 = CaseStatusTransitionService.getTransitionErrorMessage('Invalid Status', 'Any Status');
        String error3 = CaseStatusTransitionService.getTransitionErrorMessage(null, 'In Progress');
        String error4 = CaseStatusTransitionService.getTransitionErrorMessage('Engineer Dispatched', '');
        Test.stopTest();
        
        System.assert(error1.contains('Invalid status transition'), 'Should contain transition error message');
        System.assert(error1.contains('In Progress'), 'Should list valid options');
        
        System.assert(error2.contains('No valid transitions'), 'Should indicate no valid transitions');
        
        System.assert(error3.contains('cannot be empty'), 'Should handle null values');
        System.assert(error4.contains('cannot be empty'), 'Should handle blank values');
    }
    
    /**
     * @description Test getAllTransitions method
     */
    @IsTest
    static void testGetAllTransitions() {
        Test.startTest();
        List<CaseStatusTransitionService.TransitionInfo> allTransitions = CaseStatusTransitionService.getAllTransitions();
        Test.stopTest();
        
        System.assert(allTransitions.size() >= 2, 'Should have at least 2 transitions');
        
        // Verify structure of TransitionInfo
        CaseStatusTransitionService.TransitionInfo firstTransition = allTransitions[0];
        System.assertNotEquals(null, firstTransition.fromStatus, 'From status should not be null');
        System.assertNotEquals(null, firstTransition.toStatus, 'To status should not be null');
        System.assertNotEquals(null, firstTransition.isActive, 'Is active should not be null');
        System.assertNotEquals(null, firstTransition.developerName, 'Developer name should not be null');
    }
    
    /**
     * @description Test TransitionInfo wrapper class
     */
    @IsTest
    static void testTransitionInfoWrapper() {
        CaseStatusTransitionService.TransitionInfo info = new CaseStatusTransitionService.TransitionInfo();
        info.fromStatus = 'Test From';
        info.toStatus = 'Test To';
        info.isActive = true;
        info.description = 'Test Description';
        info.developerName = 'Test_Developer_Name';
        
        System.assertEquals('Test From', info.fromStatus, 'From status should be settable');
        System.assertEquals('Test To', info.toStatus, 'To status should be settable');
        System.assertEquals(true, info.isActive, 'Is active should be settable');
        System.assertEquals('Test Description', info.description, 'Description should be settable');
        System.assertEquals('Test_Developer_Name', info.developerName, 'Developer name should be settable');
    }
    
    /**
     * @description Test integration with actual metadata records
     */
    @IsTest
    static void testMetadataIntegration() {
        // This test verifies that our metadata records are properly configured
        Test.startTest();
        List<Case_Status_Transition__mdt> metadata = [
            SELECT From_Status__c, To_Status__c, Is_Active__c, Description__c
            FROM Case_Status_Transition__mdt
            WHERE Is_Active__c = true
        ];
        Test.stopTest();
        
        System.assert(metadata.size() >= 2, 'Should have at least 2 active metadata records');
        
        // Verify specific transitions exist
        Boolean foundDispatchedToProgress = false;
        Boolean foundProgressToResolved = false;
        
        for (Case_Status_Transition__mdt mdt : metadata) {
            if (mdt.From_Status__c == 'Engineer Dispatched' && mdt.To_Status__c == 'In Progress') {
                foundDispatchedToProgress = true;
            }
            if (mdt.From_Status__c == 'In Progress' && mdt.To_Status__c == 'Resolved') {
                foundProgressToResolved = true;
            }
        }
        
        System.assert(foundDispatchedToProgress, 'Should have Engineer Dispatched to In Progress transition');
        System.assert(foundProgressToResolved, 'Should have In Progress to Resolved transition');
    }
}