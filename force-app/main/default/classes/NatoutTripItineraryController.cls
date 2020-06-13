public with sharing class NatoutTripItineraryController {
    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Itinerary__c> getItineraryList(String tripId) {
        List<National_Outings_Trip_Itinerary__c> itineraryList = [
            SELECT Id, Land_Agency__c, Land_Agency__r.Name,
            Day_Number__c, Camp_Lodge_Location__c, Trails_Used__c
            FROM National_Outings_Trip_Itinerary__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY Day_Number__c
        ];
        return itineraryList;
    }
}