@isTest
public with sharing class NatoutTripBudgetExportControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Trip_Type__c = 'Backpack',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 4,
            Participants__c = 10,
            Planned_Staff__c = 2,
            Fixed_Amount__c = 10,
            Commercial_Agency_Fees__c = 10,
            Meals_Budget_Option__c = 'Day',
            Meals_First_Day__c = 1,
            Meals_Last_Day__c =2,
            Shipping__c = 10,
            Postage__c = 10,
            Communication_Devices__c = 10,
            Supplies_Equipment__c = 10,
            Wilderness_Agency_Fees__c = 10
        );
        insert trip;

        List<National_Outings_Trip_Budget_Item__c> itemList = new List<National_Outings_Trip_Budget_Item__c>();
        itemList.add(new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Item_Category__c = 'Other - airport parking, baggage fees, etc.',
            Amount__c = 10
        ));

        itemList.add(new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Meals',
            Number_Staff__c = 2,
            Staff_Amount__c = 20,
            Participant_Amount__c = 10
        ));

        itemList.add(new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Transportation',
            Amount__c = 10
        ));

        itemList.add(new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Concessionaires',
            Item_Category__c = 'Other',
            Amount__c = 10
        ));
        insert itemList;

        Id trip2Id = NatoutTripCopy.copy(trip.Id);

        NatoutTripBudgetExportController ctl = new NatoutTripBudgetExportController();
        PageReference pageRef = Page.NatoutTripBudgetExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trips', trip.Id + ',' + trip2Id);
        List<NatoutTripBudgetExportController.ExportRow> rowList = ctl.getExportList();

    }
}
