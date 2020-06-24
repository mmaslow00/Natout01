public with sharing class CreateTestData {
	static Id accountHouseholdTypeId;
	static Id contactHouseholdTypeId;
    static Id entityRecordTypeId;
	static {
		accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
		contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        entityRecordTypeId = Schema.SObjectType.Club_Entity__c.getRecordTypeInfosByName().get('Club Entity').getRecordTypeId();
	}

    public static void CreateTestData() {
        Account account1 = new Account(
            Name='Mark Maslow Household',
            RecordTypeId = accountHouseholdTypeId
        );
        insert account1;
        Contact contact1 = new Contact(
            AccountId = account1.Id,
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
        User_Lookups__c lookup = new User_Lookups__c(
            Contact__c = contact1.Id,
            User__c = UserInfo.getUserId()
        );
        insert lookup;
    }    
}
