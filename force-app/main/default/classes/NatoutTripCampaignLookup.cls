public without sharing class NatoutTripCampaignLookup {
    @AuraEnabled
    public static Decimal getTripPrice(String tripId) {
        Decimal retVal = null;
        List<Campaign> campList = [
            SELECT Id, Trip_Price__c
            FROM Campaign
            WHERE Name = :tripId
        ];
        if(campList.size() > 0) {
            retVal = campList[0].Trip_Price__c;
        }
        return retVal;
    }
}
