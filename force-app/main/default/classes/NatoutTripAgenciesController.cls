public with sharing class NatoutTripAgenciesController {
    public NatoutTripAgenciesController() {

    }
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Agency__c> getAgencyList(String tripId) {
        System.debug('Retrieving staff for trip Id: ' + tripId);
        List<National_Outings_Trip_Agency__c> agencyList = [
            SELECT Id, Account__c, Account__r.Name
            FROM National_Outings_Trip_Agency__c
            WHERE National_Outings_Trip__c = :tripId
        ];
        System.debug('Returning agencyList: ' + agencyList);
        return agencyList;
    }
}