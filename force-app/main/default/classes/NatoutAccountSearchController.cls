public with sharing class NatoutAccountSearchController {
    @AuraEnabled (cacheable=true)
    public static List<Account> getAccountList(String accountType, String searchName) {
        Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();        
        searchName = searchName + '%';
        String sql = 'SELECT Id, Name, BillingStreet, BillingCity, BillingState ' +
            'FROM Account ' +
            'WHERE ' +
            'RecordTypeId = :recTypeId ' +
            'AND Type = :accountType ' +
            'AND Name LIKE :searchName ' +
            'ORDER BY Name';

        List<Account> accountList = Database.query(sql);
        return accountList;
    }
}