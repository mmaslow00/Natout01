@isTest
public with sharing class NatoutTripPostTripReportTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(-8),
            Subcommittee__c = 'Knapsack',
            Status__c = 'Uploaded to TRAIL'
        );
        insert trip;
        NatoutTripPostTripReport.submitReport(trip.Id, 'Test Itinerary', 'Test Medical');
        trip = [
            SELECT Id, 
                Post_Trip_Report_Itinerary__c,
                Post_Trip_Report_Medical__c,
                Post_Trip_Report_Due__c, 
                Post_Trip_Report_Date_Submitted__c
            FROM National_Outings_Trip__c 
            WHERE Id=:trip.Id
        ];
        System.assertEquals('Test Itinerary', trip.Post_Trip_Report_Itinerary__c);
        System.assertEquals('Test Medical', trip.Post_Trip_Report_Medical__c);
        System.assertEquals(true, trip.Post_Trip_Report_Due__c);
        System.assertNotEquals(null, trip.Post_Trip_Report_Date_Submitted__c);
        
        List<TriggeredSendEmail__c> emailList = [
            SELECT Id from TriggeredSendEmail__c
        ];
        System.assertEquals(1, emailList.size()); 

        NatoutTripPostTripReport.submitReport(trip.Id, '', '');
        emailList = [
            SELECT Id from TriggeredSendEmail__c
        ];
        System.assertEquals(2, emailList.size()); 

    }
}