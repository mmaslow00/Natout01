@isTest
public with sharing class NatoutTripCopyTest {
    static Id accountOrgTypeId;
    static {
        accountOrgTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Subcommittee__c = 'Knapsack'
        );
        insert trip;

        National_Outings_Trip_Budget_Item__c budgetItem = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 100,
            Staff_Role__c = 'Leader',
            Item_Category__c = 'Airfare',
            Factor_Type__c = 'Dollars'
        );

        insert budgetItem;

        National_Outings_Trip_Staff__c staff = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Assistant Leader'
        );
        insert staff;

        String copyId = NatoutTripCopy.copy(trip.Id);
        List<National_Outings_Trip_Budget_Item__c> budgetList = [SELECT Id from National_Outings_Trip_Budget_Item__c where National_Outings_Trip__c = :copyId];
        System.assertEquals(1, budgetList.size());
        List<String> idList = new List<String>();
        idList.add(trip.Id);
        NatoutTripCopy.markUploaded(idList);

        trip.Subcommittee__c = 'International';
        trip.First_Time_Run__c = false;
        trip.Prior_Trip__c = 'Test';
        trip.Prior_Trip_Price__c = null;
        update trip;
        NatoutTripCopy.copy(trip.Id);
    }
}
