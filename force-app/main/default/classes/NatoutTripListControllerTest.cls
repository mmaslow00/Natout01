@isTest
public with sharing class NatoutTripListControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Status__c = 'Started',
            Trip_Type__c = 'Backpack',
            States_Provinces__c = 'CA',
            Rack_Trip__c = true,
            International_Countries__c = 'China'
        );
        insert trip;
        NatoutTripListSearchCriteria criteria = new NatoutTripListSearchCriteria();
        criteria.dtBegin = dateToString(Date.today());
        criteria.dtEnd = dateToString(Date.today());
        criteria.userTrips = true;
        List<National_Outings_Trip__c> tripList = NatoutTripListController.getTripList(criteria);
        System.assertEquals(1, tripList.size());

        criteria.userTrips = false;
        criteria.subcomm = trip.Subcommittee__c;
        criteria.status = trip.Status__c;
        criteria.type = trip.Trip_Type__c;
        criteria.state = trip.States_Provinces__c;
        criteria.nameMatch = trip.Name;
        criteria.rackTrips = true;
        criteria.country = 'China';

        tripList = NatoutTripListController.getTripList(criteria);
        System.assertEquals(1, tripList.size());
    }
    private static String dateToString(Date inputDate) {
        Date d = inputDate;
        Datetime dt = Datetime.newInstance(d.year(), d.month(),d.day());
        return dt.format('yyyy-MM-dd');
    }
}
