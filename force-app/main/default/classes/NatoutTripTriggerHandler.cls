public with sharing class NatoutTripTriggerHandler {
    public static void beforeInsert(List<National_Outings_Trip__c> tripList) {
        Id contactId = getUserContactId();
        if(contactId != null) {
            Contact userContact = [
                SELECT Name, MailingStreet, MailingCity, MailingState, MailingPostalCode
                FROM Contact
                WHERE Id = :contactId
            ];
            for(National_Outings_Trip__c trip : tripList) {
                trip.Sat_Phone_Ship_To_Name__c = userContact.Name;
                trip.Sat_Phone_Ship_To_Address__c = userContact.MailingStreet;
                trip.Sat_Phone_Ship_To_City__c = userContact.MailingCity;
                trip.Sat_Phone_Ship_To_State__c = userContact.MailingState;
                trip.Sat_Phone_Ship_To_Zip_Code__c = userContact.MailingPostalCode;
            }
        }
        return;
    }
    public static void afterInsert(List<National_Outings_Trip__c> tripList) {
        Id contactId = getUserContactId();
        if(contactId != null) {
            List<National_Outings_Trip_Staff__c> staffList = new List<National_Outings_Trip_Staff__c>();
            for(National_Outings_Trip__c trip : tripList) {
                staffList.add(
                    new National_Outings_Trip_Staff__c(
                        National_Outings_Trip__c = trip.Id,
                        Contact__c = contactId,
                        Role__c = 'Leader'
                    )
                );
            }
            insert staffList;
        }
    }
    public static void afterUpdate(List<National_Outings_Trip__c> tripList, Map<Id,National_Outings_Trip__c> oldMap ) {
        List<National_Outings_Trip__c> changedTrips = new List<National_Outings_Trip__c>();
        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
            if(prevTrip.Status__c != trip.Status__c) {
                changedTrips.add(trip);
            }
        }
        if( ! changedTrips.isEmpty() ) {
            List<TriggeredSendEmail__c> emailList =
                NatoutEmailHandler.statusChanged(changedTrips, oldMap);
            //insert emailList;
            System.debug('emailList: ' + emailList);
        }
    }
    private static Id getUserContactId() {
        Id userId = UserInfo.getUserId();
        Id contactId=null;
        if(UserInfo.getUserType() == 'Standard') {
            List<User_Lookups__c> uLookupList = [
                SELECT Contact__c FROM User_Lookups__c WHERE User__c = :userId
            ];
            if(uLookupList.size() > 0) {
                contactId = uLookupList[0].Contact__c;
            }
        }
        else {
            contactId = [select ContactId from User where Id=:userId].ContactId;
        }
        return contactId;
    }
}