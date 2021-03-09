public with sharing class NatoutTripPostTripReport {
    public static final String notificationEmailAddr = 'outings.permits@sierraclub.org';
    @AuraEnabled
    public static DateTime submitReport(
        String tripId,
        String itinerary,
        String medical
    ) {
        DateTime now = System.now();
        National_Outings_Trip__c trip = [
            SELECT Title__c FROM National_Outings_Trip__c where Id=:tripId
        ];

        National_Outings_Trip__c tripUpdate = new National_Outings_Trip__c (
            Id = tripId,
            Post_Trip_Report_Itinerary__c = itinerary,
            Post_Trip_Report_Medical__c = medical,
            Post_Trip_Report_Date_Submitted__c = now
        );
        update tripUpdate;
        String itineraryDisplay;
        String medicalDisplay;
        if(itinerary != null && itinerary.trim().length() > 0) {
            itineraryDisplay = itinerary;
        }
        else {
            itineraryDisplay = '(No Itinerary Changes reported)';
        }
        if(medical != null && medical.trim().length() > 0) {
            medicalDisplay = medical;
        }
        else {
            medicalDisplay = '(No Injuries or Medical Incidents reported)';
        }
            
        String msg = '<p>Post Use Report submitted for trip ' + trip.Title__c + '</p>' +
            '<p><b>Itinerary Changes</b></p>' +
            '<p>' + itineraryDisplay + '</p>' +
            '<p><b>Injuries or Medical Incidents</b></p>' +
            '<p>' + medicalDisplay + '</p>' +
            '<p> Trip can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId + '</p>'
        ;
        TriggeredSendEmail__c triggeredSend = NatoutEmailHandler.createTriggeredSend(
            null, 
            notificationEmailAddr, 
            'Post Use Report Submitted', 
            msg    
        );
        insert triggeredSend;
        return now;
    }
}
