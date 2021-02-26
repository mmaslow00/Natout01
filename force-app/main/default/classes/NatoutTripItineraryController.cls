public with sharing class NatoutTripItineraryController {
    private static String tripId;
    private static National_Outings_Trip__c trip;

    @AuraEnabled (cacheable=true)
    public static List<National_Outings_Trip_Itinerary__c> getItineraryList(String tripId) {
        List<National_Outings_Trip_Itinerary__c> itineraryList = [
            SELECT Id, Land_Agency__c, Land_Agency__r.Name,
            Day_Number__c, Camp_Lodge_Location__c, Trails_Used__c
            FROM National_Outings_Trip_Itinerary__c
            WHERE National_Outings_Trip__c = :tripId
            ORDER BY Day_Number__c
        ];
        return itineraryList;
    }
    public static List<PrintReport> getReportList() {
        List<National_Outings_Trip_Itinerary__c> itList = getItineraryList(getTripId());
        Date startDate = getTrip(getTripId()).Start_Date__c;
        List<PrintReport> reportList = new List<PrintReport>();
        for(National_Outings_Trip_Itinerary__c it : itList) {
            reportList.add(
                new PrintReport(
                    it.Land_Agency__r.Name,
                    it.Day_Number__c,
                    startDate.addDays(Integer.valueOf(it.Day_Number__c) - 1),
                    it.Camp_Lodge_Location__c,
                    it.Trails_Used__c
                )
            );
        }
        return reportList;
    }
    public static String getTripName() {
        return getTrip(getTripId()).Name;
    }
    private static String getTripId() {
        if(tripId == null) {
            tripId = ApexPages.currentPage().getParameters().get('id');
        }
        return tripId;
    }
    private static National_Outings_Trip__c getTrip(String tripId) {
        if(trip == null) {
            trip = [SELECT Name, Start_Date__c FROM National_Outings_Trip__c WHERE Id = :tripId];
        }
        return trip;
    }
    public class PrintReport {
        public String agency {get; set;}
        public Decimal dayNum {get; set;}
        public Date dayDate {get; set;}
        public String location {get; set;}
        public String trails {get; set;}
        public PrintReport(
            String agency,
            Decimal dayNum,
            Date dayDate,
            String location,
            String trails
        ) {
            this.agency = agency;
            this.dayNum = dayNum;
            this.dayDate = dayDate;
            this.location = location;
            this.trails = trails;
        }
    }
}