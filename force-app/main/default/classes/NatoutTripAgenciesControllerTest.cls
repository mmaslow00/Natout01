@isTest
public with sharing class NatoutTripAgenciesControllerTest {
    static Id accountOrgTypeId;
    static {
        accountOrgTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
		Account account = new Account(
            Name='Account1',
            RecordTypeId = accountOrgTypeId,
            Type = 'Ranger'
		);
        insert account;
        
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;

        National_Outings_Trip_Agency__c agency = new National_Outings_Trip_Agency__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = account.Id
        );
        insert agency;

        List<National_Outings_Trip_Agency__c> agencyList = NatoutTripAgenciesController.getAgencyList(trip.Id);

        System.assertEquals(1, agencyList.size());
    }
}