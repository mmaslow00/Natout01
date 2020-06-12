@isTest
public with sharing class NatoutAccountSearchControllerTest {
    static Id accountOrgTypeId;
    static {
        accountOrgTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
        setup();
        List<Account> accountList = NatoutAccountSearchController.getAccountList('Vendor', 'Account');
        System.assertEquals(1, accountList.size());
    }
	private static void setup() {
		Account account1 = new Account(
            Name='Account1',
            RecordTypeId = accountOrgTypeId,
            Type = 'Vendor'
		);
		insert account1;
    }
}
