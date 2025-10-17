/**
 * @description Test class demonstrating how to test Named Credentials callouts
 * Uses HttpCalloutMock to simulate external API responses
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
@IsTest
private class PartsInventoryServiceTest {
    
    /**
     * @description Mock class for simulating successful API responses
     * Returns realistic JSON response for parts inventory
     */
    private class SuccessfulCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Realistic JSON response from a Parts Inventory API
            String jsonResponse = '{'
                + '"status": "success",'
                + '"data": {'
                + '  "partNumber": "ABC123",'
                + '  "partName": "Hydraulic Pump Assembly",'
                + '  "available": true,'
                + '  "quantityInStock": 50,'
                + '  "price": 249.99,'
                + '  "currency": "USD",'
                + '  "supplier": "Industrial Parts Co.",'
                + '  "estimatedDeliveryDays": 3,'
                + '  "warehouse": "Main Warehouse - Sector 7",'
                + '  "lastUpdated": "2025-10-17T10:30:00Z"'
                + '},'
                + '"timestamp": "2025-10-17T10:30:15Z"'
                + '}';
            
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    /**
     * @description Mock class for simulating API errors
     * Returns error response in standard JSON format
     */
    private class ErrorCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Standard error response format
            String errorResponse = '{'
                + '"status": "error",'
                + '"errorCode": "SERVICE_UNAVAILABLE",'
                + '"errorMessage": "Parts inventory service is temporarily unavailable",'
                + '"details": "Database connection timeout",'
                + '"timestamp": "2025-10-17T10:30:15Z",'
                + '"supportContact": "support@parts-inventory.com"'
                + '}';
            
            res.setBody(errorResponse);
            res.setStatusCode(500);
            return res;
        }
    }
    
    /**
     * @description Mock class for part not found scenario
     */
    private class PartNotFoundMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String notFoundResponse = '{'
                + '"status": "not_found",'
                + '"errorCode": "PART_NOT_FOUND",'
                + '"errorMessage": "The requested part number does not exist",'
                + '"partNumber": "XYZ999",'
                + '"suggestions": ["XYZ998", "XYZ997"],'
                + '"timestamp": "2025-10-17T10:30:15Z"'
                + '}';
            
            res.setBody(notFoundResponse);
            res.setStatusCode(404);
            return res;
        }
    }
    
    /**
     * @description Mock class for out of stock scenario
     */
    private class OutOfStockMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String outOfStockResponse = '{'
                + '"status": "success",'
                + '"data": {'
                + '  "partNumber": "DEF456",'
                + '  "partName": "Electric Motor - 5HP",'
                + '  "available": false,'
                + '  "quantityInStock": 0,'
                + '  "price": 599.99,'
                + '  "currency": "USD",'
                + '  "supplier": "Industrial Parts Co.",'
                + '  "estimatedRestockDate": "2025-10-25",'
                + '  "alternativeParts": ["DEF457", "DEF455"]'
                + '}'
                + '}';
            
            res.setBody(outOfStockResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    
    /**
     * @description Test successful callout with Named Credentials
     */
    @IsTest
    static void testCheckPartAvailabilitySuccess() {
        // Set mock for callout
        Test.setMock(HttpCalloutMock.class, new SuccessfulCalloutMock());
        
        Test.startTest();
        String result = PartsInventoryService.checkPartAvailability('ABC123');
        Test.stopTest();
        
        // Verify response
        System.assert(result.contains('200'), 'Should return success status code');
        System.assert(result.contains('ABC123'), 'Should contain part number in response');
    }
    
    /**
     * @description Test callout error handling
     */
    @IsTest
    static void testCheckPartAvailabilityError() {
        // Set mock for error scenario
        Test.setMock(HttpCalloutMock.class, new ErrorCalloutMock());
        
        Test.startTest();
        String result = PartsInventoryService.checkPartAvailability('XYZ999');
        Test.stopTest();
        
        // Verify error handling
        System.assert(result.contains('500'), 'Should return error status code');
    }
    
    /**
     * @description Test async callout method
     */
    @IsTest
    static void testCheckPartAvailabilityAsync() {
        // Set mock for callout
        Test.setMock(HttpCalloutMock.class, new SuccessfulCalloutMock());
        
        Test.startTest();
        PartsInventoryService.checkPartAvailabilityAsync('ABC123');
        Test.stopTest();
        
        // Future method executes successfully
        System.assert(true, 'Async callout completed without exceptions');
    }
}
