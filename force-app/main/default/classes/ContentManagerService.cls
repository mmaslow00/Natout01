public with sharing class ContentManagerService {
    
    @AuraEnabled
    public static String getContentDetails(String recordId) {
        List<ContentDocumentLink> contentDocumentList = [SELECT ContentDocumentId, LinkedEntityId 
                                                            FROM   ContentDocumentLink 
                                                            WHERE  LinkedEntityId =: recordId];
        Set<Id> contentDocumentId = new Set<Id>();
            
        for(ContentDocumentLink cdl : contentDocumentList){
            contentDocumentId.add(cdl.ContentDocumentId);
        }
            
        List<ContentVersion> contentVersionList = [
            SELECT Id, FileType, Title, FileExtension,
                ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,
                CreatedDate, ContentDocumentId, ContentDocument.FileType
            FROM   ContentVersion 
            WHERE  ContentDocumentId IN : contentDocumentId
            ORDER BY CreatedDate
        ];
        return JSON.serialize(contentVersionList);
    }

    @AuraEnabled
    public static void deleteContentDocument(String recordId) {
        Database.delete(recordId);
    }
}
