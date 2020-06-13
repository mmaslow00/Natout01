public with sharing class NatoutTripStaffController {
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Staff__c> getStaffList(String tripId) {
        System.debug('Retrieving staff for trip Id: ' + tripId);
        List<National_Outings_Trip_Staff__c> staffList = [
            SELECT Id, Contact__c, Contact__r.FirstName, Contact__r.LastName,
            National_Outings_Trip__c, 
            National_Outings_Trip__r.Name,
            Role__c 
            FROM National_Outings_Trip_Staff__c
            WHERE National_Outings_Trip__c = :tripId
        ];
        return staffList;
    }
}