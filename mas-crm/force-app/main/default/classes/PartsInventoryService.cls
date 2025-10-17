/**
 * @description Demo service class showing Named Credentials integration capability
 * This demonstrates how external APIs can be integrated securely using Named Credentials
 * @author Manufacturing CRM Team
 * @since API Version 64.0
 */
public with sharing class PartsInventoryService {
    
    // Named Credential reference - stores endpoint and authentication securely
    private static final String NAMED_CREDENTIAL = 'callout:Parts_Inventory_API';
    
    /**
     * @description Simple demo method to check part availability using Named Credentials
     * @param partNumber The part number to check
     * @return String response from the external API
     */
    @AuraEnabled
    public static String checkPartAvailability(String partNumber) {
        try {
            // Build HTTP request using Named Credential
            HttpRequest req = new HttpRequest();
            req.setEndpoint(NAMED_CREDENTIAL + '/parts/' + partNumber);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000);
            
            // Send request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            // Return response (in real implementation, parse and process)
            return 'Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody();
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * @description Demo method showing future callout with Named Credentials
     * @param partNumber Part number to check asynchronously
     */
    @future(callout=true)
    public static void checkPartAvailabilityAsync(String partNumber) {
        // This demonstrates async callouts using Named Credentials
        checkPartAvailability(partNumber);
    }
}
