@isTest
public with sharing class NatoutTripFilesServiceTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Subcommittee__c = 'Knapsack'
        );
        insert trip;

        Id tripId = trip.Id;
        Id fileId = NatoutTripFilesService.saveTheChunkFile(trip.Id, 'TestFileName', 'TestContent', 'pdf', null, 'Itinerary');
        NatoutTripFilesService.saveTheChunkFile(tripId, 'TestFileName', 'TestContent', 'pdf', fileId, 'Itinerary');

        String rslts = NatoutTripFilesService.getContentDetails(tripId, 'Itinerary');
        NatoutTripFilesService.deleteContentDocument(tripId);
    }
}
