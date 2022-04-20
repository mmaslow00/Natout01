public with sharing class NatoutTripListSearchCriteria {
    @AuraEnabled
    public Boolean userTrips {get; set;}
    @AuraEnabled
    public Boolean rackTrips {get; set;}
    @AuraEnabled
    public String dtBegin {get; set;}
    @AuraEnabled
    public String dtEnd {get; set;}
    @AuraEnabled
    public String subcomm {get; set;}
    @AuraEnabled
    public String status {get; set;}
    @AuraEnabled
    public String type {get; set;}
    @AuraEnabled
    public String state {get; set;}
    @AuraEnabled
    public String country {get; set;}
    @AuraEnabled
    public String nameMatch {get; set;}
}