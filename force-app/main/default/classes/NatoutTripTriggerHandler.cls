/*
    Tests for methods in this class are in NatoutTripTriggerHandlerTest
    Except for test for afterUpdate method, which is in NatoutEmailHandlerTest
*/
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
                trip.Sat_Phone_Ship_To_State_Prov__c = userContact.MailingState;
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
        List<TriggeredSendEmail__c> emailList = new List<TriggeredSendEmail__c>();
        if( ! changedTrips.isEmpty() ) {
            emailList.addAll(NatoutEmailHandler.statusChanged(changedTrips, oldMap));
        }

        changedTrips.clear();
        for(National_Outings_Trip__c trip : tripList) {
            if(trip.Subcommittee__c == 'International') {
                National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
                if(prevTrip.Budget_Approved_Date__c == null && trip.Budget_Approved_Date__c != null) {
                    changedTrips.add(trip);
                }
            }
        }
        if( ! changedTrips.isEmpty() ) {
            emailList.addAll(NatoutEmailHandler.budgetApproved(changedTrips));
        }
        if( ! emailList.isEmpty() ) {
            //insert emailList;
            for(TriggeredSendEmail__c tse : emailList) {
                System.debug(tse.Email__c);
            }
        }
    }
    public static void beforeUpdate(List<National_Outings_Trip__c> tripList, Map<Id,National_Outings_Trip__c> oldMap) {
        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
            if(trip.Status__c == 'Submitted' && prevTrip.Status__c != 'Submitted') {
                trip.Date_Last_Submitted__c = System.now();
            }
            else {
                trip.Date_Last_Submitted__c = prevTrip.Date_Last_Submitted__c;
            }
            if(trip.Status__c == 'Returned' && prevTrip.Status__c != 'Returned') {
                trip.Date_Last_Returned__c = System.now();
            }
            else {
                trip.Date_Last_Returned__c = prevTrip.Date_Last_Returned__c;
            }
        }
    }
    public static void beforeDelete(List<National_Outings_Trip__c> tripList) {
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip__c trip : tripList) {
            tripIds.add(trip.Id);
        }

        List<ContentDocumentLink> contentDocumentList = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM   ContentDocumentLink 
            WHERE  LinkedEntityId in :tripIds
        ];
        if( ! contentDocumentList.isEmpty() ) {
            List<ContentDocument> docList = new List<ContentDocument>();    
            for(ContentDocumentLink cdl : contentDocumentList){
                docList.add(new ContentDocument(Id=cdl.ContentDocumentId));
            }
            delete docList;
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