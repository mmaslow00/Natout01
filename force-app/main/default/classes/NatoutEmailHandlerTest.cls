@isTest
public with sharing class NatoutEmailHandlerTest {
    static Id accountOrgTypeId;
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static Id entityRecordTypeId;
    static {
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        entityRecordTypeId = Schema.SObjectType.Club_Entity__c.getRecordTypeInfosByName().get('Club Entity').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
        Account householdAccount = new Account(
            Name='Account1',
            RecordTypeId = accountHouseholdTypeId
        );
        insert householdAccount;
        List<Contact> contactList = new List<Contact>();
        Contact creator = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Creator',
            Email = 'test.creator@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(creator);
        Contact subcommOfficer = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Officer',
            Email = 'test.officer@abc.com',
            MailingStreet = '1234 Main St',
            MailingCity = 'Somewhere',
            MailingState = 'CA',
            MailingPostalCode = '12345',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(subcommOfficer);
        Contact officerCollaborator = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'officerCollaborator',
            Email = 'test.officecollaborator@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(officerCollaborator);
        Contact creatorCollaborator = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'creatorCollaborator',
            Email = 'test.creatprcollaborator@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(creatorCollaborator);
        
        insert contactList;

        User_Lookups__c lookup = new User_Lookups__c(
            Contact__c = creator.Id,
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

        Club_Entity__c ent = new Club_Entity__c(
            RecordTypeId = entityRecordTypeId,
            Name = 'Knapsack',
            EntityId__c = 'KS',
            Status__c = 'Active',
            Entity_Category__c = 'Outings', 
            Type__c = 'National Outing Subcomm',
            Bypass_Validations__c = true
        );
        insert ent;
        Leader_Position__c ldrPos = new Leader_Position__c(
            Name='Chair',
            Code__c = 'CHR',
            ClubEventPermission_NonOutings__c = 'Administrator',
            ClubEventPermission_Outings__c = 'Administrator'
        );
        insert ldrPos;
        Leadership__c role = new Leadership__c(
            Club_Entity__c = ent.Id,
            Position_Active__c = true,
            Contact__c = subcommOfficer.Id,
            Leader_Position__c = ldrPos.Id
        );
        insert role;

        List<National_Outings_Trip_Collaborator__c> collabList = new List<National_Outings_Trip_Collaborator__c>();
        collabList.add(new National_Outings_Trip_Collaborator__c(
            Contact__c = creatorCollaborator.Id,
            National_Outings_Trip__c = trip.Id,
            Access__c = 'Edit'
            )
        );
        collabList.add(new National_Outings_Trip_Collaborator__c(
            Contact__c = officerCollaborator.Id,
            National_Outings_Trip__c = trip.Id,
            Access__c = 'Approve'
            )
        );
        insert collabList;

        trip.Status__c = 'Submitted';
        update trip;

        List<TriggeredSendEmail__c> emailList;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c            
        ];
        System.assertEquals(2, emailList.size());

        trip.Status__c = 'Returned';
        update trip;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c
        ];
        System.assertEquals(4, emailList.size());

        trip.Status__c = 'Submitted';
        update trip;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c
        ];
        System.assertEquals(6, emailList.size());

        trip.Status__c = 'Approved by Chair';
        update trip;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c
        ];
        System.assertEquals(8, emailList.size());

        trip.Status__c = 'Approved by Staff';
        update trip;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c
        ];
        System.assertEquals(10, emailList.size());

        National_Outings_Trip_Comments__c comments = new National_Outings_Trip_Comments__c(
            National_Outings_Trip__c = trip.Id,
            Comments__c = 'Testing comments',
            Notify_Approvers__c = true,
            Notify_Creators__c = true,
            Notify_Staff__c = true,
            Notify_Brochure_Editor__c = true
        );
        insert comments;
        emailList = [
            SELECT SubscriberKey__c FROM TriggeredSendEmail__c
        ];
        System.assertEquals(16, emailList.size());

        NatoutEmailHandler.submitBrochure(trip.Id);
    }
}
