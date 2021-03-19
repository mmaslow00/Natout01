@isTest
public with sharing class NatoutTripLinksControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Status__c = 'Started',
            Trip_Type__c = 'Backpack - California',
            States_Provinces__c = 'CA'
        );
        insert trip;
        National_Outings_Trip_Link__c tripLink = new National_Outings_Trip_Link__c (
            National_Outings_Trip__c = trip.Id,
            Url__c = 'http://www.sierraclub.org',
            Description__c = 'Sierra Club Website'
        );
        insert tripLink;
        List<National_Outings_Trip_Link__c> linkList = NatoutTripLinksController.getLinkList(trip.Id);
        System.assertEquals(1, linkList.size());
    }
}
