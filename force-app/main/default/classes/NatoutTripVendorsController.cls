public with sharing class NatoutTripVendorsController {
    public NatoutTripVendorsController() {
    }
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Vendor__c> getVendorList(String tripId) {
        List<National_Outings_Trip_Vendor__c> vendorList = [
            SELECT Id, Type__c, Account__c, Account__r.Name
            FROM National_Outings_Trip_Vendor__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY Type__c
        ];
        return vendorList;
    }
}