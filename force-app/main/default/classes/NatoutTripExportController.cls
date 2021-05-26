public with sharing class NatoutTripExportController {
    public NatoutTripExportController() {
    }
    public List<ExportRow> getExportList() {
        String idParameterString = ApexPages.currentPage().getParameters().get('trips');
        List<String> tripIdList = idParameterString.split(',');
        List<National_Outings_Trip__c> tripList = [
            SELECT
                Id, 
                Name,
                Title__c,
                Trip_Type__c,
                Subcommittee__c,
                Start_Date__c,
                End_Date__c,
                Participants__c,
                Planned_Staff__c,
                Trip_Copy__c,
                First_Time_Run__c,
                States_Provinces__c,
                Country__c,
                Latitude__c,
                Longitude__c,
                Area__c,
                Geographic_Area__c,
                Activity_Type__c,
                Group_Type__c,
                Meals_Included__c,
                Backpack_Rating__c,
                Minimum_Age__c,
                Prior_Trip_Copy_Changes__c,
                Risks_Hazards__c,
                Permit_Comments__c,
                Permit_Requirement_Options__c,
                Meals_Budget_Option__c,
                Meals_First_Day__c,
                Meals_Last_Day__c,
                Fixed_Amount__c,
                Meals_Comments__c,
                Concessionaire_Comments__c,
                Supplies_Equipment__c,
                Wilderness_Agency_Fees__c,
                Commercial_Agency_Fees__c,
                International_Countries__c,
                Leader_Driving_Participants_During_Trip__c
             FROM National_Outings_Trip__c
             WHERE Id IN :tripIdList
        ];

        Map<String, List<Staff>> staffMap = getStaffMap(tripIdList);
        Map<String, List<String>> agencyMap = getAgencyMap(tripIdList);
        Map<String, List<National_Outings_Trip_Vendor__c>> vendorMap = getVendorMap(tripIdList);
        Map<String, String> subcommCodeMap = getSubcommCodeMap();
        Map<String, String> tripTypeCodeMap = getTripTypeCodeMap();

        List<ExportRow> exportList = new List<ExportRow>();
        for(National_Outings_Trip__c trip : tripList) {
            ExportRow row = new ExportRow();
            row.id = trip.Id;
            row.name = trip.Name;
            row.title = trip.Title__c;
            row.tripType = tripTypeCodeMap.get(trip.Trip_Type__c);
            row.subcommittee = subcommCodeMap.get(trip.Subcommittee__c);
            row.startDate = formatDate(trip.Start_Date__c);
            row.endDate = formatDate(trip.End_Date__c);
            if(trip.Participants__c != null) {
                row.participants = trip.Participants__c.intValue();
            }
            if(trip.Planned_Staff__c != null) {
                row.plannedStaff = trip.Planned_Staff__c.intValue();
            }
            row.tripCopy = trip.Trip_Copy__c;
            row.tripCopy = row.tripCopy.replaceAll('â', '');
            row.tripCopy = row.tripCopy.replaceAll('€', '');
            row.tripCopy = row.tripCopy.replaceAll('™', '');
            row.tripCopy = row.tripCopy.replaceAll('œ', '');

            row.wordCount = wordCount(trip.Trip_Copy__c);
            row.firstTimeRun = trip.First_Time_Run__c;
            row.tripCopyChanges = trip.Prior_Trip_Copy_Changes__c;

            if(trip.States_Provinces__c != null) {
                List<String> states = trip.States_Provinces__c.split(';');
                if(states.size() > 0) {
                    row.state1 = states[0];
                }
                if(states.size() > 1 ) {
                    row.state2 = states[1];
                }
                if(states.size() > 2) {
                    row.state3 = states[2];
                }
            }
            row.latitude = trip.Latitude__c;
            row.longitude = trip.Longitude__c;
            if(trip.Subcommittee__c == 'International') {
                row.landArea1 = trip.Geographic_Area__c;
                if(trip.International_Countries__c != null) {
                    String[] countries = trip.International_Countries__c.split(';');
                    for(String country : countries) {
                        if(row.country1 == null) {
                            row.country1 = country;
                        }
                        else if(row.country2 == null) {
                            row.country2 = country;
                        }
                        else if(row.country3 == null) {
                            row.country3 = country;
                        }
                    }
                }
            }
            else {
                row.country1 = trip.Country__c;
                if(trip.Area__c != null) {
                    String[] areas = trip.Area__c.split(';');
                    for(String area : areas) {
                        if(row.landArea1 == null) {
                            row.landArea1 = area;
                        }
                        else if(row.landArea2 == null) {
                            row.landArea2 = area;
                        }
                        else if(row.landArea3 == null) {
                            row.landArea3 = area;
                        }
                    }
                }
            }
            row.risks = trip.Risks_Hazards__c;
            if(trip.Activity_Type__c != null) {
                String[] activityTypes = trip.Activity_Type__c.split(';');
                for(String type : activityTypes) {
                    if(row.activityType1 == null) {
                        row.activityType1 = type;
                    }
                    else if(row.activityType2 == null) {
                        row.activityType2 = type;
                    }
                    else if(row.activityType3 == null) {
                        row.activityType3 = type;
                    }
                }
            }
            row.groupType = trip.Group_Type__c;
            row.mealsIncluded = trip.Meals_Included__c;
            row.backpackRating = trip.Backpack_Rating__c;
            if(trip.Minimum_Age__c != null) {
                row.minimumAge = trip.Minimum_Age__c.intValue();
            }

            List<Staff> staffList = staffMap.get(trip.Id);
            if(staffList != null) {
                for(Staff stf : staffList) {
                    if(stf.role == 'Leader') {
                        row.staffRole1 = stf.role;
                        row.staffName1 = stf.name;
                        row.staffExternalId1 = stf.externalId;
                    }
                    else if(row.staffRole2 == null) {
                        row.staffRole2 = stf.role;
                        row.staffName2 = stf.name;
                        row.staffExternalId2 = stf.externalId;
                    }
                    else if(row.staffRole3 == null) {
                        row.staffRole3 = stf.role;
                        row.staffName3 = stf.name;
                        row.staffExternalId3 = stf.externalId;
                    }
                    else if(row.staffRole4 == null) {
                        row.staffRole4 = stf.role;
                        row.staffName4 = stf.name;
                        row.staffExternalId4 = stf.externalId;
                    }
                }
            }
            row.permitRequirements = trip.Permit_Requirement_Options__c;
            row.permitComments = trip.Permit_Comments__c;
            List<String> agencyList = agencyMap.get(trip.Id);
            if(agencyList != null) {
                for(String agency : agencyList) {
                    if(row.landAgency1 == null) {
                        row.landAgency1 = agency;
                    }
                    else if(row.landAgency2 == null) {
                        row.landAgency2 = agency;
                    }
                    else if(row.landAgency3 == null) {
                        row.landAgency3 = agency;
                    }
                }
            }
            row.mealsOption = trip.Meals_Budget_Option__c;
            row.mealsFirstDay = trip.Meals_First_Day__c;
            row.mealsLastDay = trip.Meals_Last_Day__c;
            row.fixedAmount = trip.Fixed_Amount__c;
            row.mealsComments = trip.Meals_Comments__c;
            row.concessionaireComments = trip.Concessionaire_Comments__c;

            List<National_Outings_Trip_Vendor__c> vendorList = vendorMap.get(trip.Id);
            if( vendorList != null ) {
                for(National_Outings_Trip_Vendor__c vendor : vendorList) {
                    if(row.vendor1Name == null) {
                        row.vendor1Name = vendor.Account__r.Name;
                        row.vendor1Type = vendor.Type__c;
                    }
                    else if(row.vendor2Name == null) {
                        row.vendor2Name = vendor.Account__r.Name;
                        row.vendor2Type = vendor.Type__c;
                    }
                    else if(row.vendor3Name == null) {
                        row.vendor3Name = vendor.Account__r.Name;
                        row.vendor3Type = vendor.Type__c;
                    }
                    else if(row.vendor4Name == null) {
                        row.vendor4Name = vendor.Account__r.Name;
                        row.vendor4Type = vendor.Type__c;
                    }
                    else if(row.vendor5Name == null) {
                        row.vendor5Name = vendor.Account__r.Name;
                        row.vendor5Type = vendor.Type__c;
                    }
                }
            }
            row.leaderDrivingParticipants = trip.Leader_Driving_Participants_During_Trip__c;

            exportList.add(row);
        }
        return exportList;
    }
    private String formatDate(Date input) {
        String timeZone = System.UserInfo.getTimeZone().getID();
        Time zTime = Time.newInstance(0,0,0,0);
        return DateTime.newInstance(input, zTime).format('yyyyMMdd', timeZone);
    }
    private Map<String, List<Staff>> getStaffMap(List<String> tripIdList) {
        Map<String, List<Staff>> tripStaffMap = new Map<String, List<Staff>>();
        List<National_Outings_Trip_Staff__c> staffList = [
            SELECT 
                Id,
                National_Outings_Trip__c,
                Contact__r.Name,
                Contact__r.External_ID__c,
                Role__c
             FROM National_Outings_Trip_Staff__c
             WHERE National_Outings_Trip__c in :tripIdList
             ORDER BY National_Outings_Trip__c
        ];
        if(staffList.isEmpty()) {
            return tripStaffMap;
        }
        String lastTripId = staffList[0].National_Outings_Trip__c;
        List<Staff> tripStaffList = new List<Staff>();
        for(National_Outings_Trip_Staff__c staff : staffList) {
            if(staff.National_Outings_Trip__c != lastTripId) {
                tripStaffMap.put(lastTripId, tripStaffList);
                lastTripId = staff.National_Outings_Trip__c;
                tripStaffList = new List<Staff>();
            }
            Staff tripStaff = new Staff();
            tripStaff.externalId = staff.Contact__r.External_ID__c;
            tripStaff.name = staff.Contact__r.Name;
            tripStaff.Role = staff.Role__c;
            tripStaffList.add(tripStaff);
        }
        tripStaffMap.put(lastTripId, tripStaffList);

        return tripStaffMap;
    }
    private Map<String, List<String>> getAgencyMap(List<String> tripIdList) {
        Map<String, List<String>> agencyMap = new Map<String, List<String>>();
        List<National_Outings_Trip_Agency__c> agencyList = [
            SELECT
                National_Outings_Trip__c,  
                Account__r.External_Id__c
            FROM National_Outings_Trip_Agency__c
            WHERE National_Outings_Trip__c in :tripIdList
        ];
        if(agencyList.isEmpty()) {
            return agencyMap;
        }
        String lastTripId = agencyList[0].National_Outings_Trip__c;
        List<String> tripAgencyList = new List<String>();
        for(National_Outings_Trip_Agency__c agency : agencyList) {
            if(agency.National_Outings_Trip__c != lastTripId) {
                agencyMap.put(lastTripId, tripAgencyList);
                lastTripId = agency.National_Outings_Trip__c;
                tripAgencyList = new List<String>();
            }
            tripAgencyList.add(agency.Account__r.External_ID__c);
        }
        agencyMap.put(lastTripId, tripAgencyList);

        return agencyMap;
    }
    private Map<String, List<National_Outings_Trip_Vendor__c>> getVendorMap(List<String> tripIdList) {
        Map<String, List<National_Outings_Trip_Vendor__c>> vendorMap = new Map<String, List<National_Outings_Trip_Vendor__c>>();
        List<National_Outings_Trip_Vendor__c> vendorList = [
            SELECT National_Outings_Trip__c, Account__r.Name, Type__c
            FROM National_Outings_Trip_Vendor__c
            WHERE National_Outings_Trip__c IN :tripIdList
        ];
        if(vendorList.isEmpty()) {
            return vendorMap;
        }
        String lastTripId = vendorList[0].National_Outings_Trip__c;
        List<National_Outings_Trip_Vendor__c> tripVendorList = new List<National_Outings_Trip_Vendor__c>();
        for(National_Outings_Trip_Vendor__c vendor : vendorList) {
            if(vendor.National_Outings_Trip__c != lastTripId) {
                vendorMap.put(lastTripId, tripVendorList);
                lastTripId = vendor.National_Outings_Trip__c;
                tripVendorList = new List<National_Outings_Trip_Vendor__c>();
            }
            tripVendorList.add(vendor);
        }
        vendorMap.put(lastTripId, tripVendorList);

        return vendorMap;
    }
    private Integer wordCount(String input) {
        if(input == null) {
            return 0;
        }
        //normalizeSpace removes duplicate spaces
        //replaceAll removes all non-spaces
        //Number of words is number of spaces + 1
        return input.normalizeSpace().replaceAll('\\S', '').length() + 1;
    }
    private Map<String, String> getSubcommCodeMap() {
        List<National_Outings_Subcommittee_Values__mdt> subcommList = [
            SELECT Label, TRAIL_Code__c
            FROM National_Outings_Subcommittee_Values__mdt
        ];
        Map<String, String> subcommCodeMap = new Map<String, String>();
        for(National_Outings_Subcommittee_Values__mdt values : subcommList) {
            subcommCodeMap.put(values.Label, values.TRAIL_Code__c);
        }
        return subcommCodeMap;
    }
    private Map<String, String> getTripTypeCodeMap() {
        List<National_Outings_Trip_Type_Values__mdt> typeList = [
            SELECT Label, TRAIL_Code__c
            FROM National_Outings_Trip_Type_Values__mdt
        ];
        Map<String, String> tripTypeCodeMap = new Map<String, String>();
        for(National_Outings_Trip_Type_Values__mdt values : typeList) {
            tripTypeCodeMap.put(values.Label, values.TRAIL_Code__c);
        }
        return tripTypeCodeMap;
    }
    public class ExportRow {
        public String id {get; set;}
        public String name {get; set;}
        public String title {get; set;}
        public String tripType {get; set;}
        public String subcommittee {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public Integer participants {get; set;}
        public Integer plannedStaff {get; set;}
        public String tripCopy {get; set;}
        public Integer wordCount {get; set;}
        public String tripCopyChanges {get; set;}

        public Boolean firstTimeRun {get; set;}
        public String state1 {get; set;}
        public String state2 {get; set;}
        public String state3 {get; set;}
        public String country1 {get; set;}
        public String country2 {get; set;}
        public String country3 {get; set;}
        public Decimal latitude {get; set;}
        public Decimal longitude {get; set;}
        public String landArea1 {get; set;}
        public String landArea2 {get; set;}
        public String landArea3 {get; set;}
        public String risks {get; set;}
        public String activityType1 {get; set;}
        public String activityType2 {get; set;}
        public String activityType3 {get; set;}
        public String groupType {get; set;}
        public String mealsIncluded {get; set;}
        public String backpackRating {get; set;}
        public Integer minimumAge {get; set;}
        public String staffRole1 {get; set;}
        public String staffName1 {get; set;}
        public String staffExternalId1 {get; set;}
        public String staffRole2 {get; set;}
        public String staffName2 {get; set;}
        public String staffExternalId2 {get; set;}
        public String staffRole3 {get; set;}
        public String staffName3 {get; set;}
        public String staffExternalId3 {get; set;}
        public String staffRole4 {get; set;}
        public String staffName4 {get; set;}
        public String staffExternalId4 {get; set;}
        public String permitRequirements {get; set;}
        public String permitComments {get; set;}
        public String landAgency1 {get; set;}
        public String landAgency2 {get; set;}
        public String landAgency3 {get; set;}
        public String mealsOption {get; set;}
        public Decimal mealsFirstDay {get; set;}
        public Decimal mealsLastDay {get; set;}
        public Decimal fixedAmount {get; set;}
        public String mealsComments {get; set;}
        public String concessionaireComments {get; set;}
        public String vendor1Name {get; set;}
        public String vendor1Type {get; set;}
        public String vendor2Name {get; set;}
        public String vendor2Type {get; set;}
        public String vendor3Name {get; set;}
        public String vendor3Type {get; set;}
        public String vendor4Name {get; set;}
        public String vendor4Type {get; set;}
        public String vendor5Name {get; set;}
        public String vendor5Type {get; set;}
        public Boolean leaderDrivingParticipants {get; set;}
    }
    private class Staff {
        public String externalId {get; set;}
        public String name {get; set;}
        public String role {get; set;}
        public Boolean isLeader() {
            return this.role == 'Leader';
        }
    }
}