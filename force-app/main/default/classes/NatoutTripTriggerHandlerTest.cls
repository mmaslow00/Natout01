@isTest
public with sharing class NatoutTripTriggerHandlerTest {
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static {
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
		Account householdAccount = new Account(
            Name='Account1',
            RecordTypeId = accountHouseholdTypeId
        );
        insert householdAccount;
        Contact contact1 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact1',
            Email = 'test1.contact1@abc.com',
            MailingStreet = '1234 Main St',
            MailingCity = 'Somewhere',
            MailingState = 'CA',
            MailingPostalCode = '12345',
            RecordTypeId = contactHouseholdTypeId
        );
        insert contact1;
        User_Lookups__c lookup = new User_Lookups__c(
            Contact__c = contact1.Id,
            User__c = UserInfo.getUserId()
        );
        insert lookup;

        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;

        Id tripId = trip.Id;
        Id contactId = contact1.Id;
        List<National_Outings_Trip_Staff__c> staffList = [
            SELECT Id 
            FROM National_Outings_Trip_Staff__c
            WHERE National_Outings_Trip__c = :tripId
            AND Contact__c = :contactId
        ];
        System.assertEquals(1, staffList.size());
    }
}
