public with sharing class NatoutConvertFiles {
    public static void convert() {
        List<National_Outings_Trip__c> tripList =
        [SELECT Id FROM National_Outings_Trip__c];
    
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip__c trip : tripList) {
            tripIds.add(trip.Id);
        }
        
        List<ContentDocumentLink> docList = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :tripIds
        ];
        System.debug('docList: ' + docList);
        
        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink link : docList) {
            docIds.add(link.ContentDocumentId);
        }
        
        List<ContentVersion> versionList = [
            SELECT Id FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            AND Category__c = null
        ];
        System.debug('count to update: ' + versionList.size());
        
        List<ContentVersion> listToUpdate = new List<ContentVersion>();
        for(ContentVersion vers : versionList) {
            listToUpdate.add(new ContentVersion(Id = vers.Id, Category__c = 'Itinerary'));
        }
        System.debug('listToUpdate: ' + listToUpdate);
        
        update listToUpdate;
    }
}
