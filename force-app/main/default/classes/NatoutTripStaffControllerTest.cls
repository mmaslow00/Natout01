@isTest
public with sharing class NatoutTripStaffControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;
     
        National_Outings_Trip_Staff__c staff = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Leader'
        );
        insert staff;
        List<National_Outings_Trip_Staff__c> staffList = NatoutTripStaffController.getStaffList(trip.Id);
        System.assertEquals(1, staffList.size());
    }
}
