public with sharing class NatoutTripOptions {
    @AuraEnabled (cacheable=true)
    public static TripOptions getOptions() {
        TripOptions tripOptions = new TripOptions();
        
        List<National_Outings_Subcommittee_Values__mdt> subCommValues = [
            SELECT Label
            FROM National_Outings_Subcommittee_Values__mdt
            ORDER BY Label
        ];
        for(National_Outings_Subcommittee_Values__mdt option : subCommValues) {
            tripOptions.subcommList.add(option.Label);
        }

        List<National_Outings_Trip_Type_Values__mdt> tripTypeValues = [
            SELECT Label
            FROM National_Outings_Trip_Type_Values__mdt
            ORDER BY Label
        ];
        for(National_Outings_Trip_Type_Values__mdt option : tripTypeValues) {
            tripOptions.tripTypeList.add(option.Label);
        }

        List<National_Outings_Country__mdt> countryValues = [
            SELECT Label
            FROM National_Outings_Country__mdt
            ORDER BY Label
        ];
        for(National_Outings_Country__mdt option : countryValues) {
            tripOptions.countryList.add(option.Label);
        }

        tripOptions.stateList = getStateOptions();        

        return tripOptions;
    }
    @AuraEnabled (cacheable=true)
    public static VendorOptions getVendorOptions() {
        List<National_Outings_Vendor_Type__mdt> typeList = [
            SELECT Label, Domestic__c, International__c
            FROM National_Outings_Vendor_Type__mdt
            ORDER BY Label
        ];
        VendorOptions opts = new VendorOptions();
        for(National_Outings_Vendor_Type__mdt vend : typeList) {
            if(vend.Domestic__c) {
                opts.domesticList.add(vend.Label);
            }
            if(vend.International__c) {
                opts.internationalList.add(vend.Label);
            }
        }
        return opts;
    }
    public static List<LabelValue> getStateOptions() {
        List<LabelValue> stateList = new List<LabelValue>();
        for(National_Outings_State__mdt state : 
            [
                SELECT Label, Code__c
                FROM National_Outings_State__mdt
                ORDER BY Label
            ]) {
                stateList.add(new LabelValue(state.Label, state.Code__c));
            }
        return stateList;
    }
    public class TripOptions {
        @AuraEnabled
        public List<String> subcommList = new List<String>();
        @AuraEnabled
        public List<String> tripTypeList = new List<String>();
        @AuraEnabled
        public List<String> countryList = new List<String>();
        @AuraEnabled
        public List<LabelValue> stateList = new List<LabelValue>();
    }
    public class VendorOptions {
        @AuraEnabled
        public List<String> domesticList = new List<String>();
        @AuraEnabled
        public List<String> internationalList = new List<String>();
    }
    public class LabelValue {
        public LabelValue(String label, String value) {
            this.label = label;
            this.value = value;
        }
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
    }
}