public with sharing class CreateTestData {
	static Id accountHouseholdTypeId;
	static Id contactHouseholdTypeId;
	static {
		accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
		contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
	}

    public CreateTestData() {
        //List<Account> accList = new List<Account>();
        Account account1 = new Account(
            Name='Mark Maslow Household',
            RecordTypeId = accountHouseholdTypeId
        );
        insert account1;
		contact1 = new Contact(
            AccountId = account1.Id,
            FirstName = 'Mark',
            LastName = 'Maslow',
            Email = 'test1.contact1@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        insert contact1;
    }
}
