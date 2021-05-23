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
            End_Date__c = Date.today() + 2,
            Status__c = 'Started'
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

        Contact contact2 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact2',
            Email = 'test1.contact2@abc.com',
            MailingStreet = '4321 Main St',
            MailingCity = 'Somewhere',
            MailingState = 'CA',
            MailingPostalCode = '54321',
            RecordTypeId = contactHouseholdTypeId
        );
        insert contact2;
        National_Outings_Trip_Staff__c staff = new National_Outings_Trip_Staff__c(
            id=staffList[0].Id,
            Contact__c = contact2.Id
        );
        update staff;

        trip.Subcommittee__c = 'International';
        trip.Status__c = 'Submitted';
        update trip;
        trip.Status__c = 'Returned';
        update trip;
        trip.Status__c = 'Submitted';
        update trip;
        trip.Status__c = 'Returned';
        update trip;
        trip.Budget_Approved_Date__c = System.now();
        update trip;

        Id fileId = FileUploadService.saveTheChunkFile(trip.Id, 'TestFileName', 'TestContent', 'pdf', null);

        List<ContentDocumentLink> contentDocumentList = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM   ContentDocumentLink 
            WHERE  LinkedEntityId = :tripId
        ];
        System.assertEquals(1, contentDocumentList.size());

        Id docId = contentDocumentList[0].ContentDocumentId;
        List<ContentDocument> docList = [
            SELECT Id FROM ContentDocument WHERE Id = :docId
        ];
        System.assertEquals(1, docList.size());

        delete trip;

        docList = [
            SELECT Id FROM ContentDocument WHERE Id = :docId
        ];
        System.assertEquals(0, docList.size());
    }
}
