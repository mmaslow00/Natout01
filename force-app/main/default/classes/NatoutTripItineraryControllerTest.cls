@isTest
public with sharing class NatoutTripItineraryControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;
     
        National_Outings_Trip_Itinerary__c itinerary = new National_Outings_Trip_Itinerary__c(
            National_Outings_Trip__c = trip.Id,
            Day_Number__c = 1
        );
        insert itinerary;
        List<National_Outings_Trip_Itinerary__c> itineraryList = NatoutTripItineraryController.getItineraryList(trip.Id);
        System.assertEquals(1, itineraryList.size());

        NatoutTripItineraryController ctl = new NatoutTripItineraryController();
        PageReference pageRef = Page.NatoutTripItineraryReport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', trip.Id);
        List<NatoutTripItineraryController.PrintReport> reportList = ctl.getReportList();
    }
}
