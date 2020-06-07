public with sharing class NatoutTripVendorExportController {
    public NatoutTripVendorExportController() {

    }
    public List<ExportRow> getExportList() {
        String idParameterString = ApexPages.currentPage().getParameters().get('trips');
        List<String> tripIdList = idParameterString.split(',');
        List<ExportRow> rowList = new List<ExportRow>();
        for(National_Outings_Trip_Vendor__c vendor : [
            SELECT 
                National_Outings_Trip__c,
                Type__c,
                Account__r.Name
            FROM National_Outings_Trip_Vendor__c
            WHERE National_Outings_Trip__c IN :tripIdList
            ]
        ) {
            rowList.add(
                new ExportRow(
                    vendor.National_Outings_Trip__c,
                    vendor.Type__c,
                    vendor.Account__r.Name
                )
            );
        }
        return rowList;
    }
    public Class ExportRow {
        public ExportRow(String tripId, String type, String name) {
            this.tripId = tripId;
            this.type = type;
            this.name = name;
        }
        public String tripId {get; set;}
        public String type {get; set;}
        public String name {get; set;}
    }
}