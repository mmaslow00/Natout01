@isTest
public with sharing class NatoutTripBudgetControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2
        );
        insert trip;
        
        National_Outings_Trip_Budget_Item__c item = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 10
        );
        insert item;
        List<National_Outings_Trip_Budget_Item__c> volTravList = NatoutTripBudgetController.getVolTravelList(trip.Id);
        System.assertEquals(1, volTravList.size());

        item = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Meals',
            Amount__c = 10
        );
        insert item;    
        List<National_Outings_Trip_Budget_Item__c> mealsList = NatoutTripBudgetController.getMealsList(trip.Id);
        System.assertEquals(1, mealsList.size());

        item = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Transportation',
            Amount__c = 10
        );
        insert item;    
        List<National_Outings_Trip_Budget_Item__c> transportList = NatoutTripBudgetController.getTransportationList(trip.Id);
        System.assertEquals(1, transportList.size());

        item = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Concessionaires',
            Amount__c = 10
        );
        insert item;    
        List<National_Outings_Trip_Budget_Item__c> concessList = NatoutTripBudgetController.getConcessionaireList(trip.Id);
        System.assertEquals(1, concessList.size());
    }
}
