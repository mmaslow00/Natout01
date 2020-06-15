@isTest
public with sharing class NatoutTripBudgetReportControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Subcommittee__c = 'Knapsack',
            Wilderness_Agency_Fees__c = 100,
            Commercial_Agency_Fees__c = 100,
            Postage__c = 20,
            Communication_Devices__c = 20,
            Shipping__c = 20,
            Supplies_Equipment__c = 20,
            Meals_Budget_Option__c = 'Subcommittee',
            Fixed_Amount__c = 20,
            Participants__c = 12,
            Planned_Staff__c = 2,
            First_Time_Run__c = true,
            Trip_Type__c = 'Backpack - California',
            Meals_First_Day__c = 25,
            Meals_Last_Day__c = 25
        );
        insert trip;

        List<National_Outings_Trip_Budget_Item__c> itemList = new List<National_Outings_Trip_Budget_Item__c>();

        National_Outings_Trip_Budget_Item__c airfare = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 100,
            Staff_Role__c = 'Leader',
            Item_Category__c = 'Airfare',
            Factor_Type__c = 'Dollars'
        );
        itemList.add(airfare);
        National_Outings_Trip_Budget_Item__c mileage = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 100,
            Staff_Role__c = 'Co-Leader',
            Item_Category__c = 'Mileage',
            Factor_Type__c = 'Miles'
        );
        itemList.add(mileage);
        National_Outings_Trip_Budget_Item__c subsistence1 = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 100,
            Staff_Role__c = 'Cook',
            Item_Category__c = 'Subsistence',
            Factor_Type__c = 'Days'
        );
        itemList.add(subsistence1);
        National_Outings_Trip_Budget_Item__c subsistence2 = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Volunteer Travel',
            Amount__c = 100,
            Staff_Role__c = 'Asst Leader',
            Item_Category__c = 'Subsistence',
            Factor_Type__c = 'Days'
        );
        itemList.add(subsistence2);
        National_Outings_Trip_Budget_Item__c bus = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Transportation',
            Amount__c = 100,
            Item_Category__c = 'Bus',
            Option__c = 'Trip'
        );
        itemList.add(bus);
        National_Outings_Trip_Budget_Item__c gratuities1 = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Transportation',
            Amount__c = 100,
            Item_Category__c = 'Gratuities',
            Option__c = 'Participants'
        );
        itemList.add(gratuities1);
        National_Outings_Trip_Budget_Item__c gratuities2 = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Transportation',
            Amount__c = 80,
            Item_Category__c = 'Gratuities',
            Option__c = 'Staff'
        );
        itemList.add(gratuities2);
        National_Outings_Trip_Budget_Item__c concess1 = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Concessionaires',
            Amount__c = 100,
            Item_Category__c = 'Campground',
            Option__c = 'Trip'
        );
        itemList.add(concess1);
        National_Outings_Trip_Budget_Item__c meals = new National_Outings_Trip_Budget_Item__c(
            National_Outings_Trip__c = trip.Id,
            Budget_Category__c = 'Meals',
            Staff_Amount__c = 20,
            Number_Staff__c = 2,
            Participant_Amount__c = 20
        );
        itemList.add(meals);

        insert itemList;

        NatoutTripBudgetReportController ctl = new NatoutTripBudgetReportController();
        PageReference pageRef = Page.NatoutTripBudgetReport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trip', trip.Id);

        NatoutTripBudgetReportController.VolTravel volTravel = ctl.getVolTravel();
        Decimal role1Total = volTravel.getRole1Total();
        Decimal role2Total = volTravel.getRole2Total();
        Decimal role3Total = volTravel.getRole3Total();
        Decimal role4Total = volTravel.getRole4Total();
        Decimal grandTotal1 = volTravel.getGrandTotal();
        for(NatoutTripBudgetReportController.VolTravelRow row : volTravel.itemList) {
            Decimal role1Amount = row.getRole1Amount();
            Decimal role2Amount = row.getRole2Amount();
            Decimal role3Amount = row.getRole3Amount();
            Decimal role4Amount = row.getRole4Amount();
            Decimal categoryTotal = row.getCategoryTotal();
        }
        NatoutTripBudgetReportController.BudgetCategory transport = ctl.getTransport();
        Decimal tripTotal = transport.getTripTotal();
        Decimal staffTotal = transport.getStaffTotal();
        Decimal partTotal = transport.getPartTotal();
        Decimal grandTotal2 = transport.getGrandTotal();
        NatoutTripBudgetReportController.BudgetCategory concess = ctl.getConcessionaires();
        NatoutTripBudgetReportController.SimpleList other = ctl.getOtherList();
        Decimal tripPrice = ctl.getTripPrice();
        for(NatoutTripBudgetReportController.BudgetRow row : transport.itemList) {
            Decimal tripAmount = row.getTripAmount();
            Decimal staffAmount = row.getStaffAmount();
            Decimal partAmount = row.getPartAmount();
            Decimal totalAmount = row.getTotalAmount();
        }

        trip.Meals_Budget_Option__c = 'Day';
        update trip;
        ctl = new NatoutTripBudgetReportController();
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trip', trip.Id);
        NatoutTripBudgetReportController.SimpleList mealsList = ctl.getMeals();

        trip.Meals_Budget_Option__c = 'None';
        update trip;
        ctl = new NatoutTripBudgetReportController();
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trip', trip.Id);
        mealsList = ctl.getMeals();

        trip.Participants__c = null;
        trip.Meals_Budget_Option__c = 'Day';
        update trip;
        ctl = new NatoutTripBudgetReportController();
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trip', trip.Id);
        mealsList = ctl.getMeals();

        Decimal total = mealsList.getTotal();
        for(NatoutTripBudgetReportController.SimpleRow row : ctl.getOtherList().itemList) {
            Decimal amount = row.getAmount();
        }
        tripPrice = ctl.getTripPrice();

    }
}
