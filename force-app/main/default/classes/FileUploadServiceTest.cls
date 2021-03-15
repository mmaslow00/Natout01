@isTest
public with sharing class FileUploadServiceTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Subcommittee__c = 'Knapsack'
        );
        insert trip;

        Id tripId = trip.Id;
        Id fileId = FileUploadService.saveTheChunkFile(trip.Id, 'TestFileName', 'TestContent', 'pdf', null);
        FileUploadService.saveTheChunkFile(tripId, 'TestFileName', 'TestContent', 'pdf', fileId);

        List<ContentDocumentLink> contentDocumentList = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM   ContentDocumentLink 
            WHERE  LinkedEntityId = :tripId
        ];
        System.assertEquals(1, contentDocumentList.size());
    }
}
