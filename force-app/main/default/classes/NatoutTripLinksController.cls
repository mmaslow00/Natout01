public with sharing class NatoutTripLinksController {
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Link__c> getLinkList(String tripId) {
        List<National_Outings_Trip_Link__c> linkList = [
            SELECT Id, Url__c, Description__c
            FROM National_Outings_Trip_Link__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY CreatedDate
        ];
        return linkList;
    }
}
