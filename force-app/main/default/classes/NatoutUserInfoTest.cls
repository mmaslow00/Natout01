@isTest
public with sharing class NatoutUserInfoTest {
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static Id entityRecordTypeId;
	static Id profileId;
    static {
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        entityRecordTypeId = Schema.SObjectType.Club_Entity__c.getRecordTypeInfosByName().get('Club Entity').getRecordTypeId();
		profileId = [SELECT Id FROM profile WHERE name = 'AddUp User'].Id;
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

        NatoutUserInfo.UserAccess uAccess = NatoutUserInfo.getUserAccess(trip.Id);
        System.assertEquals(true, uAccess.canEdit);
        System.assertEquals(false, uAccess.canApprove);
        System.assertEquals(false, uAccess.isAdmin);

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
			Contact__c = contact1.Id,
			Leader_Position__c = ldrPos.Id
		);
		insert role;

        Id contactId = contact1.Id;
        String subcommName = trip.Subcommittee__c;

        uAccess = NatoutUserInfo.getUserAccess(trip.Id);
        System.assertEquals(true, uAccess.canEdit);
        System.assertEquals(true, uAccess.canApprove);
        System.assertEquals(false, uAccess.isAdmin);

        Contact contact2 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact2',
            Email = 'test2.contact2@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        insert contact2;
        User user2 = createUser(contact2);
        System.runAs(user2) {
            uAccess = NatoutUserInfo.getUserAccess(trip.Id);
            System.assertEquals(false, uAccess.canEdit);
            System.assertEquals(false, uAccess.canApprove);
            System.assertEquals(false, uAccess.isAdmin);
        }
        
        National_Outings_Trip_Collaborator__c collab = new National_Outings_Trip_Collaborator__c(
            National_Outings_Trip__c = trip.Id,
            Contact__c = contact2.Id,
            Access__c = 'Edit'
        );
        insert collab;

        System.runAs(user2) {
            uAccess = NatoutUserInfo.getUserAccess(trip.Id);
            System.assertEquals(true, uAccess.canEdit);
            System.assertEquals(false, uAccess.canApprove);
            System.assertEquals(false, uAccess.isAdmin);
        }
        collab.Access__c = 'Approve';
        update collab;
        System.runAs(user2) {
            uAccess = NatoutUserInfo.getUserAccess(trip.Id);
            System.assertEquals(true, uAccess.canEdit);
            System.assertEquals(true, uAccess.canApprove);
            System.assertEquals(false, uAccess.isAdmin);
        }

        uAccess = NatoutUserInfo.getUserAccess('');
        System.assertEquals(false, uAccess.canEdit);
        System.assertEquals(false, uAccess.canApprove);
        System.assertEquals(false, uAccess.isAdmin);

        National_Outings_Admin__c admin = new National_Outings_Admin__c(
            User__c = UserInfo.getUserId()
        );
        insert admin;
        uAccess = NatoutUserInfo.getUserAccess(trip.Id);
        System.assertEquals(true, uAccess.canEdit);
        System.assertEquals(true, uAccess.canApprove);
        System.assertEquals(true, uAccess.isAdmin);
    }
	private static User createUser(Contact ctct) {
		String FirstName = ctct.FirstName;
		String LastName = ctct.LastName;
		String Email = ctct.Email;

		string aliasText = '';
		if (FirstName != null && FirstName != '' && Lastname.length() > 1) {
			aliasText = FirstName.substring(0, 1);
		}
		if (Lastname != null && Lastname != '' && Lastname.length() > 2) {
			aliasText += Lastname.substring(0, 3);
		}
		else {
			aliasText += Lastname;
		}
		String myNickName = '';
		If (Email.length() > 40) {
			myNickName = Email.substring(0, 40);
		} else {
			myNickName = Email;
		}
		User usr = new User(firstName = FirstName,
		                    lastName = LastName,
		                    Email = Email,
		                    CommunityNickname = myNickName,
		                    languagelocalekey = 'en_US',
		                    localesidkey = UserInfo.getLocale(),
		                    emailEncodingKey = 'UTF-8',
		                    timeZoneSidKey = 'America/Los_Angeles',
		                    profileId = profileId,
		                    userName = Email,
		                    ContactId = ctct.Id,
		                    alias = aliasText);
		return usr;
	}
}
