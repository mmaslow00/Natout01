@isTest
public with sharing class NatoutLeaderSearchControllerTest {
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static Contact contact1;
    static Account account1;
    static {
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
        setup();
        List<NatoutLeaderSearchController.SearchResult> resultList =
            NatoutLeaderSearchController.getLeaderList('Contact', 'Test');
        System.assertEquals(1, resultList.size());
    }
	private static void setup() {
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

		Club_Entity__c ent = new Club_Entity__c(
			EntityId__c = 'NOSB',
			Status__c = 'Active',
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
    }

}
