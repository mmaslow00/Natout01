public with sharing class NatoutTripBudgetReportController {
    public NatoutTripBudgetReportController() {
    }
    private List<National_Outings_Trip_Budget_Item__c> budgetList;
    private National_Outings_Trip__c theTrip;
    private National_Outings_Subcommittee_Values__mdt subcommValues;
    private National_Outings_Trip_Type_Values__mdt tripTypeValues;
    private VolTravel volTravelSummary;
    private BudgetCategory transportSummary;
    private BudgetCategory concessionaireSummary;
    private SimpleList otherSummary;
    private SimpleList standardValuesSummary;
    private SimpleList mealsSummary;

    public Pagereference checkForNulls() {
        National_Outings_Trip__c trip = getTrip();
        if(trip.Participants__c == null || trip.Planned_Staff__c == null) {
            Pagereference pageRef = new Pagereference('/apex/NatoutTripBudgetReportError');
            pageRef.setRedirect(true);
            return pageRef;
        }
        return null;
    }
    private List<National_Outings_Trip_Budget_Item__c> getBudgetList() {
        if(budgetList == null) {
            String idParameter = ApexPages.currentPage().getParameters().get('trip');
            budgetList = [
                SELECT 
                    National_Outings_Trip__c,
                    Amount__c,
                    Budget_Category__c,
                    Item_Category__c,
                    Option__c,
                    Number_Staff__c,
                    Participant_Amount__c,
                    Staff_Amount__c,
                    Staff_Role__c,
                    Factor_Type__c
                FROM National_Outings_Trip_Budget_Item__c
                WHERE National_Outings_Trip__c = :idParameter
                ORDER BY Budget_Category__c, Item_Category__c
            ];
        }
        return budgetList;
    }
    private National_Outings_Trip__c getTrip() {
        if(theTrip == null) {
            String idParameter = ApexPages.currentPage().getParameters().get('trip');
            theTrip = [
                SELECT
                    Start_Date__c,
                    End_Date__c,
                    Subcommittee__c, 
                    Wilderness_Agency_Fees__c,
                    Commercial_Agency_Fees__c,
                    Postage__c,
                    Communication_Devices__c,
                    Shipping__c,
                    Supplies_Equipment__c,
                    Meals_Budget_Option__c,
                    Fixed_Amount__c,
                    Participants__c,
                    Planned_Staff__c,
                    First_Time_Run__c,
                    Trip_Type__c,
                    Meals_First_Day__c,
                    Meals_Last_Day__c
                FROM National_Outings_Trip__c
                WHERE Id = :idParameter
            ];
        }
        return theTrip;
    }
    private National_Outings_Subcommittee_Values__mdt getSubcommValues() {
        if(subcommValues == null) {
            String subComm = getTrip().Subcommittee__c;
            subcommValues = [
                SELECT 
                Conservation_Allocation__c,
                Copying__c,
                Postage__c,
                Shipping__c,
                Subcommittee_Allocation__c,
                Supplies__c,
                Telephone__c,
                First_Last_Meals__c,
                Full_Day_Meals__c,
                Subsistence__c,
                Mileage__c
                FROM National_Outings_Subcommittee_Values__mdt
                WHERE Label = :subComm
            ];
        }
        return subcommValues;
    }
    private National_Outings_Trip_Type_Values__mdt getTripTypeValues() {
        if(tripTypeValues == null) {
            String tripType = getTrip().Trip_Type__c;
            tripTypeValues = [
                SELECT Overhead_Amount1__c, Overhead_Amount2__c
                FROM National_Outings_Trip_Type_Values__mdt
                WHERE Label = :tripType
            ];
        }
        return tripTypeValues;
    }
    private List<National_Outings_Trip_Budget_Item__c> getCategory(String category) {
        List<National_Outings_Trip_Budget_Item__c> retList = new List<National_Outings_Trip_Budget_Item__c>();
        for(National_Outings_Trip_Budget_Item__c item : getBudgetList()) {
            if(item.Budget_Category__c == category) {
                retList.add(item);
            }
        }
        return retList;
    }
    public Boolean getIsInternationalTrip() {
        return getTrip().Trip_Type__c == 'International';
    }
    public VolTravel getVolTravel() {
        if(volTravelSummary == null) {
            Map<String, VolTravelRow> categoryMap = new Map<String, VolTravelRow>();
            List<National_Outings_Trip_Budget_Item__c> budgetList = getCategory('Volunteer Travel');
            VolTravel retVal = new VolTravel();
            Set<String> budgetedRoles = new Set<String>();
            for(National_Outings_Trip_Budget_Item__c budgetItem : budgetList) {
                if( ! budgetedRoles.contains(budgetItem.Staff_Role__c)) {
                    if(retval.role1 == null) {
                        retVal.role1 = budgetItem.Staff_Role__c;
                    }
                    else if(retVal.role2 == null) {
                        retVal.role2 = budgetItem.Staff_Role__c;
                    }
                    else if(retVal.role3 == null) {
                        retVal.role3 = budgetItem.Staff_Role__c;
                    }
                    else if(retVal.role4 == null) {
                        retVal.role4 = budgetItem.Staff_Role__c;
                    }
                    budgetedRoles.add(budgetItem.Staff_Role__c);
                }
                VolTravelRow row = categoryMap.get(budgetItem.Item_Category__c);
                if(row == null) {
                    row = new VolTravelRow();
                    row.category = budgetItem.Item_Category__c;
                    categoryMap.put(budgetItem.Item_Category__c, row);
                }
                if(budgetItem.Staff_Role__c == retVal.role1) {
                    row.role1Amount += getVolTravelAmount(budgetItem.Factor_Type__c, budgetItem.Amount__c);
                }
                else if(budgetItem.Staff_Role__c == retVal.role2) {
                    row.role2Amount += getVolTravelAmount(budgetItem.Factor_Type__c, budgetItem.Amount__c);
                }
                else if(budgetItem.Staff_Role__c == retVal.role3) {
                    row.role3Amount += getVolTravelAmount(budgetItem.Factor_Type__c, budgetItem.Amount__c);
                }
                else if(budgetItem.Staff_Role__c == retVal.role4) {
                    row.role4Amount += getVolTravelAmount(budgetItem.Factor_Type__c, budgetItem.Amount__c);
                }
            }
            retVal.itemList = categoryMap.values();
            volTravelSummary = retVal;
        }
        return volTravelSummary;
    }
    private Decimal getVolTravelAmount(String factor, Decimal amount) {
        National_Outings_Subcommittee_Values__mdt values = getSubcommValues();
        Decimal total;
        switch on factor {
            when 'Days' {
                total = amount * values.Subsistence__c;
            }
            when 'Miles' {
                total = amount * values.mileage__c;
            }            
            when else {
              total = amount;  
            }
        }
        return total;
    }
    public BudgetCategory getTransport() {
        if(transportSummary == null) {
            transportSummary = getBudgetCategory('Transportation');
        }
        return transportSummary;
    }
    public BudgetCategory getConcessionaires() {
        if(concessionaireSummary == null) {
            concessionaireSummary = getBudgetCategory('Concessionaires');
        }
        return concessionaireSummary;
    }
    public SimpleList getOtherList() {
        if(otherSummary == null) {
            SimpleList otherList = new SimpleList();
            National_Outings_Trip__c trip = getTrip();
            otherList.add('Wilderness Agency Fees', trip.Wilderness_Agency_Fees__c);
            otherList.add('Commercial Agency Fees', trip.Commercial_Agency_Fees__c);
            otherList.add('Postage', trip.Postage__c);
            otherList.add('Communication Devices', trip.Communication_Devices__c);
            otherList.add('Shipping', trip.Shipping__c);
            otherList.add('Supplies and Equipment', trip.Supplies_Equipment__c);
            otherSummary = otherList;
        }
        return otherSummary;
    }
    public BudgetCategory getBudgetCategory(String category) {
        Map<String, BudgetRow> budgetMap = new Map<String, BudgetRow>();
        List<National_Outings_Trip_Budget_Item__c> budgetList = getCategory(category);
        BudgetCategory retVal = new BudgetCategory();
        for(National_Outings_Trip_Budget_Item__c budgetItem : budgetList) {
            BudgetRow row = budgetMap.get(budgetItem.Item_Category__c);
            if(row == null) {
                row = new BudgetRow();
                row.itemName = budgetItem.Item_Category__c;
                budgetMap.put(row.itemName, row);
            }
            switch on budgetItem.Option__c {
                when 'Staff' {
                    Decimal numStaff = budgetItem.Number_Staff__c == null ? getTrip().Planned_Staff__c : budgetItem.Number_Staff__c;
                    if(numStaff == null) {
                        numStaff = 0;
                    }
                    row.staffAmount += (budgetItem.Amount__c * numStaff);
                }
                when 'Participants' {
                    Decimal numParts = getTrip().Participants__c;
                    if(numParts == null) {
                        numParts = 0;
                    }
                    row.partAmount += (budgetItem.Amount__c * numParts);
                    row.part80Amount += (budgetItem.Amount__c * math.round(numParts * .8));
                }
                when 'Trip' {
                    row.tripAmount += budgetItem.Amount__c;
                }
            }
        }
        retVal.itemList = budgetMap.values();
        return retVal;
    }
    public SimpleList getStandardValues() {
        if(standardValuesSummary == null) {
            String subComm = getTrip().Subcommittee__c;
            National_Outings_Subcommittee_Values__mdt values = getSubcommValues();
            SimpleList retVal = new SimpleList();
            if(values != null) {
                retVal.add('Conservation Allocation', values.Conservation_Allocation__c);
                retVal.add('Copying', values.Copying__c);
                retVal.add('Postage', values.Postage__c);
                retVal.add('Shipping', values.Shipping__c);
                retVal.add('Subcommittee Allocation', values.Subcommittee_Allocation__c);
                retVal.add('Supplies', values.Supplies__c);
                retVal.add('Telephone', values.Telephone__c);
            }
            standardValuesSummary = retVal;
        }
    return standardValuesSummary;
    }
    public SimpleList getMeals() {
        if(mealsSummary == null) {
            SimpleList retVal = new SimpleList();
            National_Outings_Trip__c trip = getTrip();
            if(trip.Meals_Budget_Option__c == 'None') {
                return retVal;
            } else if(trip.Participants__c == null) {
                return retVal;
            }
            National_Outings_Subcommittee_Values__mdt values = getSubcommValues();
            Integer tripDays = trip.Start_Date__c.daysBetween(trip.End_Date__c) + 1;
            Decimal staffCost=0;
            Decimal partCost=0;
            Decimal part80Cost=0;
            Decimal fixedAmount = 0;
            if(trip.Meals_Budget_Option__c == 'Subcommittee') {
                staffCost =
                    (trip.Planned_Staff__c * (trip.Meals_First_Day__c + trip.Meals_Last_Day__c) * values.First_Last_Meals__c) +
                    (trip.Planned_Staff__c * (tripDays - 2) * values.Full_Day_Meals__c);
                partCost =
                    (trip.Participants__c * (trip.Meals_First_Day__c + trip.Meals_Last_Day__c) * values.First_Last_Meals__c) +
                    (trip.Participants__c * (tripDays - 2) * values.Full_Day_Meals__c);
                part80Cost =
                    (math.round(trip.Participants__c * .8) * (trip.Meals_First_Day__c + trip.Meals_Last_Day__c) * values.First_Last_Meals__c) +
                    (math.round(trip.Participants__c *.8) * (tripDays - 2) * values.Full_Day_Meals__c);
                fixedAmount = trip.Fixed_Amount__c;
            }
            else if(trip.Meals_Budget_Option__c == 'Day') {
                for(National_Outings_Trip_Budget_Item__c item : getBudgetList()) {
                    if(item.Budget_Category__c == 'Meals') {
                        staffCost += item.Staff_Amount__c * item.Number_Staff__c;
                        partCost += item.Participant_Amount__c * trip.Participants__c;
                        part80Cost += (item.Participant_Amount__c * math.round(trip.Participants__c * .8));
                    }
                }
                fixedAmount = trip.Fixed_Amount__c;
            }
            SimpleRow partMeals = new SimpleRow('Participant Meals', partCost);
            partMeals.part80Amount = part80Cost;
            partMeals.staffAmount = staffCost;
            retVal.itemList.add(partMeals);
            retVal.add('Staff Meals', staffCost);
            retVal.add('Fixed Amount', trip.Fixed_Amount__c);
            mealsSummary = retVal;
            mealsSummary.fixedAmount = fixedAmount;
        }
        return mealsSummary;
    }

    public Decimal getTripPrice() {
        if(getTrip().Participants__c == null) {
            return null;
        }
        Decimal totalCost =
            getVolTravel().getGrandTotalAmount() + getMeals().getTotalPart80Amount() + getMeals().getStaffAmount() +
            getTransport().getPart80GrandTotal() + getOtherList().getTotalAmount() + 
            getStandardValues().getTotalAmount() + getConcessionaires().getPart80GrandTotal();

        totalCost += getOverhead();
        Decimal costPerPart = totalCost / math.round(getTrip().Participants__c * .8);
        Decimal roundedCost = 5 * math.round(costPerPart / 5);

        return roundedCost;
    }
    private Decimal getOverhead() {
        National_Outings_Trip_Type_Values__mdt values = getTripTypeValues();
        Decimal overhead = 0;
        if(values != null) {
            if(values.Overhead_Amount2__c > 0) {
                if(getTrip().First_Time_Run__c) {
                    overhead = values.Overhead_Amount2__c;
                }
            }
            if(overhead == 0) {
                overhead = values.Overhead_Amount1__c;
            }
        }
        return overhead;
    }
    public List<IntlRow> getIntlRevenue() {
        List<IntlRow> rpt = new List<IntlRow>();
        Decimal parts80 = math.round(getTrip().Participants__c * .8);
        rpt.add(
            new IntlRow(
                'Number of Participants',
                parts80,
                getTrip().Participants__c
            )
        );
        rpt.add(
            new IntlRow(
                'Estimated Trip Price',
                getTripPrice() ,
                getTripPrice()
            )
        );
        Decimal total80 =
            getVolTravel().getGrandTotalAmount() + 
            getMeals().getTotalPart80Amount() + getMeals().getStaffAmount() +
            getTransport().getPart80GrandTotal() +
            getConcessionaires().getPart80GrandTotal() +
            getOtherList().getTotalAmount() +
            getStandardValues().getTotalAmount()
        ;
        Decimal total100 =
            getVolTravel().getGrandTotalAmount() + 
            getMeals().getTotalAmount() + 
            getTransport().getGrandTotalAmount() +
            getConcessionaires().getGrandTotalAmount() +
            getOtherList().getTotalAmount() +
            getStandardValues().getTotalAmount()
        ;
        rpt.add(
            new IntlRow(
                'Revenue',
                (getTripPrice() * math.round(getTrip().Participants__c * .8)),
                (getTripPrice() * getTrip().Participants__c)
            )
        );
               
        return rpt;
    }
    public List<IntlRow> getIntlExpenses() {
        List<IntlRow> rpt = new List<IntlRow>();
        rpt.add(
            new IntlRow(
                'Volunteer Travel',
                getVolTravel().getGrandTotalAmount(),
                getVolTravel().getGrandTotalAmount()
            )
        );
        if(getMeals().getTotalAmount() > 0) {
            rpt.add(
                new IntlRow(
                    'Meals',
                    getMeals().getTotalPart80Amount() + getMeals().getStaffAmount(),
                    getMeals().getTotalAmount()
                )
            );
        }
        if(getTransport().getGrandTotal() > 0) {
            rpt.add(
                new IntlRow(
                    'On Trip Transportation',
                    getTransport().getPart80GrandTotal(),
                    getTransport().getGrandTotal()            
                )
            );
        }   
        if(getConcessionaires().getGrandTotalAmount() > 0) {
            rpt.add(
                new IntlRow(
                    'Concessionaires/Leader Planned Arrangements',
                    getConcessionaires().getPart80GrandTotal(),
                    getConcessionaires().getGrandTotal()
                )
            );
        }
        if(getOtherList().getTotalAmount() > 0) {
            rpt.add(
                new IntlRow(
                    'Other',
                    getOtherList().getTotal(),
                    getOtherList().getTotal()
                )
            );
        }
        rpt.add(
            new IntlRow(
                'Subcommittee Standard Values',
                getStandardValues().getTotalAmount(),
                getStandardValues().getTotalAmount()
            )
        );
        Decimal total80 =
            getVolTravel().getGrandTotalAmount() + 
            getMeals().getTotalPart80Amount() + getMeals().getStaffAmount() +
            getTransport().getPart80GrandTotal() +
            getConcessionaires().getPart80GrandTotal() +
            getOtherList().getTotalAmount() +
            getStandardValues().getTotalAmount() 
        ;
        Decimal total100 =
            getVolTravel().getGrandTotalAmount() + 
            getMeals().getTotalAmount() + 
            getTransport().getGrandTotalAmount() +
            getConcessionaires().getGrandTotalAmount() +
            getOtherList().getTotalAmount() +
            getStandardValues().getTotalAmount()
        ;
        rpt.add(
            new IntlRow(
                'Total Field Expenses',
                total80,
                total100
            )
        );
        rpt.add(
            new IntlRow(
                null,
                null,
                null
            )
        );
        rpt.add(
            new IntlRow(
                'Overhead Contribution',
                (getTripPrice() * math.round(getTrip().Participants__c * .8)) - total80,
                (getTripPrice() * getTrip().Participants__c) - total100
            )
        );
        return rpt;
    }
    public class BudgetCategory {
        public BudgetCategory() {
            this.itemList = new List<BudgetRow>();
        }
        public List<BudgetRow> itemList {get; set;}
        public Decimal getTripTotal() {
            Decimal total = 0;
            for(BudgetRow row : itemList) {
                total += row.tripAmount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getPartTotal() {
            Decimal total = 0;
            for(BudgetRow row : itemList) {
                total += row.partAmount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getStaffTotal() {
            Decimal total = 0;
            for(BudgetRow row : itemList) {
                total += row.staffAmount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getGrandTotal() {
            Decimal total = getGrandTotalAmount();
            return total > 0 ? total : null;
        }
        public Decimal getGrandTotalAmount() {
            Decimal total = 0;
            for(BudgetRow row : itemList) {
                total += row.getRowAmount();
            }
            return total;
        }
        Decimal getPart80GrandTotal() {
            Decimal total = 0;
            for(BudgetRow row : itemList) {
                total += row.getRowPart80Amount();
            }
            return total;
        }
    }
    public class BudgetRow {
        public String itemName {get; set;}
        public Decimal tripAmount=0;
        public Decimal partAmount=0;
        public Decimal staffAmount=0;
        Decimal part80Amount=0;
        public Decimal getTripAmount() {
            return tripAmount > 0 ? tripAmount : null;
        }
        public Decimal getPartAmount() {
            return partAmount > 0 ? partAmount : null;
        }
        public Decimal getStaffAmount() {
            return staffAmount > 0 ? staffAmount : null;
        }
        public Decimal getTotalAmount() {
            Decimal retVal = tripAmount + partAmount + staffAmount;
            return retVal > 0 ? retVal : null;
        }
        Decimal getRowAmount() {
            return tripAmount + partAmount + staffAmount;
        }
        Decimal getRowPart80Amount() {
            return tripAmount + part80Amount + staffAmount;
        } 
    }
    public class VolTravel {
        public VolTravel() {
            this.itemList = new List<VolTravelRow>();
        }
        public String role1 {get; set;}
        public String role2 {get; set;}
        public String role3 {get; set;}
        public String role4 {get; set;}
        public List<VolTravelRow> itemList {get; set;}
        public Decimal getRole1Total() {
            Decimal total = 0;
            for (VolTravelRow row : itemList) {
                total += row.role1Amount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getRole2Total() {
            Decimal total = 0;
            for (VolTravelRow row : itemList) {
                total += row.role2Amount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getRole3Total() {
            Decimal total = 0;
            for (VolTravelRow row : itemList) {
                total += row.role3Amount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getRole4Total() {
            Decimal total = 0;
            for (VolTravelRow row : itemList) {
                total += row.role4Amount;
            }
            return total > 0 ? total : null;
        }
        public Decimal getGrandTotal() {
            Decimal total = getGrandTotalAmount();
            return total > 0 ? total : null;
        }
        public Decimal getGrandTotalAmount() {
            Decimal total = 0;
            for (VolTravelRow row : itemList) {
                total += row.role1Amount + row.role2Amount + row.role3Amount + row.role4Amount;
            }
            return total;
        }
    }
    public class VolTravelRow {
        public VolTravelRow () {
            this.role1Amount = 0;
            this.role2Amount = 0;
            this.role3Amount = 0;
            this.role4Amount = 0;
        }
        public String category {get; set;}
        Decimal role1Amount;
        public Decimal getRole1Amount() {
            return role1Amount > 0 ? role1Amount : null;
        }
        Decimal role2Amount;
        public Decimal getRole2Amount() {
            return role2Amount > 0 ? role2Amount : null;
        }
        Decimal role3Amount;
        public Decimal getRole3Amount() {
            return role3Amount > 0 ? role3Amount : null;
        }
        Decimal role4Amount;
        public Decimal getRole4Amount() {
            return role4Amount > 0 ? role4Amount : null;
        }
        public Decimal getCategoryTotal() {
            return role1Amount + role2Amount + role3Amount + role4Amount;
        }
    }
    public class SimpleList {
        public SimpleList() {
            this.itemList = new List<SimpleRow>();
        }
        void add(String name, Decimal amount) {
            if(amount > 0) {
                this.itemList.add(new SimpleRow(name, amount));
            }
        }
        public List<SimpleRow> itemList {get; set;}
        public Decimal getTotal() {
            Decimal total = getTotalAmount();
            return total > 0 ? total : null;
        }
        public Decimal getTotalAmount() {
            Decimal total = 0;
            for(SimpleRow row : itemList) {
                if(row.amount > 0 && row.itemName != 'Fixed Amount') {
                    total += row.amount;
                }
            }
            return total + getFixedAmount();
        }
        public Decimal getTotalPart80Amount() {
            Decimal total = 0;
            for(SimpleRow row : itemList) {
                total += row.part80Amount;
            }
            return total + getFixedAmount();
        }
        public Decimal getStaffAmount() {
            Decimal total = 0;
            for(SimpleRow row : itemList) {
                if(row.amount > 0 && row.itemName == 'Staff Meals') {
                    total += row.amount;
                }
            }
            return total;
        }
        public Decimal fixedAmount;
        public Decimal getFixedAmount() {
            return fixedAmount == null ? 0 : fixedAmount;
        }
    }
    public class SimpleRow {
        public SimpleRow(String itemName, Decimal amount) {
            this.itemName = itemName;
            this.amount = amount;
            this.part80Amount = 0;
            this.staffAmount = 0;
        }
        public String itemName {get; set;}
        Decimal amount;
        Decimal part80Amount;
        Decimal staffAmount;
        public Decimal getAmount() {
            return amount > 0 ? amount : null;
        }
    }
    public class IntlRow {
        public IntlRow(String label, Decimal c80, Decimal c100) {
            this.label = label;
            this.c80 = c80;
            this.c100 = c100;
        }
        public String label {get; set;}
        public Decimal c80 {get; set;}
        public Decimal c100 {get; set;}
    }
}