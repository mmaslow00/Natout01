@isTest
public with sharing class NatoutTripVendorsControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;
     
        National_Outings_Trip_Vendor__c vendor = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Type__c = 'Lodging'
        );
        insert vendor;
        List<National_Outings_Trip_Vendor__c> vendorList = NatoutTripVendorsController.getVendorList(trip.Id);
        System.assertEquals(1, vendorList.size());
    }
}
