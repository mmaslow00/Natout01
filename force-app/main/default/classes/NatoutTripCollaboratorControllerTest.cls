@isTest
public with sharing class NatoutTripCollaboratorControllerTest {
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static Contact contact1;
    static Account account1;
    static {
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    }
 static testMethod void myUnitTest() {
    Account account1 = new Account(
        Name='Account1',
        RecordTypeId = accountHouseholdTypeId
    );
    insert account1;
    contact1 = new Contact(
        AccountId = account1.Id,
        FirstName = 'Test',
        LastName = 'Contact1',
        Email = 'test1.contact1@abc.com',
        RecordTypeId = contactHouseholdTypeId
    );
    insert contact1;
    National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;
     
        National_Outings_Trip_Collaborator__c collaborator = new National_Outings_Trip_Collaborator__c(
            National_Outings_Trip__c = trip.Id,
            Contact__c = contact1.Id,
            Access__c = 'Edit'
        );
        insert collaborator;
        List<National_Outings_Trip_Collaborator__c> collaboratorList = NatoutTripCollaboratorController.getCollaboratorList(trip.Id);
        System.assertEquals(1, collaboratorList.size());
    }
}
