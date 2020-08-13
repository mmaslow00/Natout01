public with sharing class NatoutTripBudgetExportController {
    public NatoutTripBudgetExportController() {

    }
    public List<ExportRow> getExportList() {
        String idParameterString = ApexPages.currentPage().getParameters().get('trips');
        List<String> tripIdList = idParameterString.split(',');
        List<National_Outings_Trip__c> allTripsList = [
            SELECT
                Id,
                Fixed_Amount__c,
                Commercial_Agency_Fees__c,
                Meals_Budget_Option__c,
                Meals_First_Day__c,
                Meals_Last_Day__c,
                Shipping__c,
                Postage__c,
                Communication_Devices__c,
                Supplies_Equipment__c,
                Wilderness_Agency_Fees__c,
                Participants__c
            FROM National_Outings_Trip__c
            WHERE Id IN :tripIdList
        ];
        List<National_Outings_Trip_Budget_Item__c> allTripBudgetsList = [
            SELECT 
                National_Outings_Trip__c,
                Amount__c,
                Budget_Category__c,
                Item_Category__c,
                Option__c,
                Number_Staff__c,
                Participant_Amount__c,
                Staff_Amount__c,
                Staff_Role__c
            FROM National_Outings_Trip_Budget_Item__c
            WHERE National_Outings_Trip__c IN :tripIdList
            ORDER BY National_Outings_Trip__c, Budget_Category__c, Item_Category__c
        ];
        Map<Id, List<National_Outings_Trip_Budget_Item__c>> allTripBudgetsMap  = new Map<Id, List<National_Outings_Trip_Budget_Item__c>>();
        if( ! allTripBudgetsList.isEmpty() ) {
            Id lastId = allTripBudgetsList[0].National_Outings_Trip__c;
            List<National_Outings_Trip_Budget_Item__c> tripBudgetList = new List<National_Outings_Trip_Budget_Item__c>();
            for(National_Outings_Trip_Budget_Item__c item : allTripBudgetsList) {
                if(item.National_Outings_Trip__c != lastId) {
                    allTripBudgetsMap.put(lastId, tripBudgetList);
                    tripBudgetList = new List<National_Outings_Trip_Budget_Item__c>();
                    lastId = item.National_Outings_Trip__c;
                }
                tripBudgetList.add(item);
            }
            allTripBudgetsMap.put(lastId, tripBudgetList);
        }

        List<ExportRow> rowList = new List<ExportRow>();
        for(National_Outings_Trip__c trip : allTripsList) {
            List<National_Outings_Trip_Budget_Item__c> tripBudgetList = allTripBudgetsMap.get(trip.Id);
            List<ExportRow> tripList = exportTripRows(trip, tripBudgetList);
            rowList.addAll(tripList);
        }

        return rowList;
    }
    private List<ExportRow> exportTripRows(National_Outings_Trip__c trip, List<National_Outings_Trip_Budget_Item__c> budgetList) {
        List<ExportRow> rowsToExport = new List<ExportRow>();
        List<National_Outings_Trip_Budget_Item__c> mealsList = new List<National_Outings_Trip_Budget_Item__c>();
        for(National_Outings_Trip_Budget_Item__c item : budgetList) {
            if(item.Budget_Category__c == 'Meals') {
                mealsList.add(item);
            }
            else {
                ExportRow row = new ExportRow(trip.Id);
                row.itemName = item.Item_Category__c;
                if(item.Budget_Category__c == 'Concessionaires') {
                    if(item.Item_Category__c == 'Other') {
                        row.itemName = 'Other - Concessionaire';
                    }
                }
                row.amount = item.Amount__c;
                row.numStaff = item.Number_Staff__c;
                if(item.Budget_Category__c == 'Volunteer Travel') {
                    row.role = item.Staff_Role__c;
                }
                else {
                    row.role = item.Option__c;
                }
                rowsToExport.add(row);
            }
        }
        if(trip.Meals_Budget_Option__c == 'Day') {
            Decimal staffAmount = 0;
            Decimal participantAmount = 0;
            if( ! mealsList.isEmpty() ) {
                for(National_Outings_Trip_Budget_Item__c item : mealsList) {
                    staffAmount += (item.Staff_Amount__c * item.Number_Staff__c);
                    participantAmount += (item.Participant_Amount__c);
                }
            }
            if(staffAmount + participantAmount > 0) {
                ExportRow row = new ExportRow(trip.Id);
                row.itemName = 'Total Staff Meals';
                row.role = 'Budget by Day';
                row.amount = staffAmount;
                rowsToExport.add(row);

                row = new ExportRow(trip.Id);
                row.itemName = 'Total Meals per Participant';
                row.role = 'Budget by Day';
                row.amount = participantAmount;
                rowsToExport.add(row);
            }
        }
        if(trip.Wilderness_Agency_Fees__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Wilderness Agency Fees';
            row.amount = trip.Wilderness_Agency_Fees__c;
            rowsToExport.add(row);
        }
        if(trip.Commercial_Agency_Fees__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Commercial Agency Fees';
            row.amount = trip.Commercial_Agency_Fees__c;
            rowsToExport.add(row);
        }
        if(trip.Postage__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Postage';
            row.amount = trip.Postage__c;
            rowsToExport.add(row);
        }
        if(trip.Communication_Devices__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Communication Devices';
            row.amount = trip.Communication_Devices__c;
            rowsToExport.add(row);
        }
        if(trip.Shipping__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Shipping';
            row.amount = trip.Shipping__c;
            rowsToExport.add(row);
        }
        if(trip.Supplies_Equipment__c != null) {
            ExportRow row = new ExportRow(trip.Id);
            row.itemName = 'Supplies and Equipment';
            row.amount = trip.Supplies_Equipment__c;
            rowsToExport.add(row);
        }
        ExportRow row = new ExportRow(trip.Id);
        row.itemName = 'Meals Fixed Amount';
        row.amount = trip.Fixed_Amount__c;
        rowsToExport.add(row);
        
        return rowsToExport;
    }
    public Class ExportRow {
        public ExportRow(String tripId) {
            this.tripId = tripId;
        }
        public String tripId {get; set;}
        public String itemName {get; set;}
        public String role {get; set;}
        public Decimal amount {get; set;}
        public Decimal numStaff {get; set;}
    }
}