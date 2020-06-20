@isTest
public with sharing class NatoutTripExportControllerTest {
    static Id accountOrgTypeId;
    static Id accountHouseholdTypeId;
    static Id contactHouseholdTypeId;
    static {
        accountOrgTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();
        accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    }
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Title__c = 'Test Trip',
            Trip_Type__c = 'Backpack - California',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 4,
            Participants__c = 10,
            Planned_Staff__c = 2,
            Trip_Copy__c = 'Test trip',
            First_Time_Run__c = false,
            States__c = 'CA;NV;OR',
            Country__c = 'USA',
            Latitude__c = 90,
            Longitude__c = -120,
            Area__c = 'Big Sur;Big Basin;Big Horn',
            Geographic_Area__c = 'Asia',
            Activity_Type__c = 'Backpack;Bicycle;Base Camp',
            Group_Type__c = 'Multigenerational',
            Meals_Included__c = 'All',
            Backpack_Rating__c = '1 - Least Difficult',
            Minimum_Age__c = 16,
            Prior_Trip_Copy_Changes__c = 'Changes',
            Risks_Hazards__c = 'Risks and Hazards',
            Permit_Comments__c = 'Permit Comments',
            Permit_Requirement_Options__c = 'Permit Associate Staff will obtain Commercial Permit (s)',
            Meals_Budget_Option__c = 'Subcommittee',
            Meals_First_Day__c = 1,
            Meals_Last_Day__c = 2,
            Fixed_Amount__c = 10,
            Meals_Comments__c = 'Commment',
            Concessionaire_Comments__c = 'Commment',
            Supplies_Equipment__c = 10,
            Wilderness_Agency_Fees__c = 10,
            Commercial_Agency_Fees__c = 10,
            International_Countries__c = 'abc;def;ghi',
            Leader_Driving_Participants_During_Trip__c = true
        );
        insert trip;

        List<Account> accountList = new List<Account>();
		Account householdAccount = new Account(
            Name='Account1',
            RecordTypeId = accountHouseholdTypeId
        );
        accountList.add(householdAccount);
        Account vendorAccount1 = new Account(
            Name='Vendor Account 1',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(vendorAccount1);
        Account vendorAccount2 = new Account(
            Name='Vendor Account 2',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(vendorAccount2);
        Account vendorAccount3 = new Account(
            Name='Vendor Account 3',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(vendorAccount3);
        Account vendorAccount4 = new Account(
            Name='Vendor Account 4',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(vendorAccount4);
        Account vendorAccount5 = new Account(
            Name='Vendor Account 5',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(vendorAccount5);

        Account agency1 = new Account(
            Name='Agency 1',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(agency1);
        Account agency2 = new Account(
            Name='Agency 2',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(agency2);
        Account agency3 = new Account(
            Name='Agency 3',
            RecordTypeId = accountOrgTypeId
        );
        accountList.add(agency3);

        insert accountList;

        List<Contact> contactList = new List<Contact>();
        Contact contact1 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact1',
            Email = 'test1.contact1@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(contact1);
        Contact contact2 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact2',
            Email = 'test2.contact2@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(contact2);
        Contact contact3 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact3',
            Email = 'test3.contact3@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(contact3);
        Contact contact4 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact4',
            Email = 'test4.contact4@abc.com',
            RecordTypeId = contactHouseholdTypeId
        );
        contactList.add(contact4);
        insert contactList;

        List<National_Outings_Trip_Staff__c> staffList = new List<National_Outings_Trip_Staff__c>();
        National_Outings_Trip_Staff__c staff1 = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Leader',
            Contact__c = contact1.Id
        );
        staffList.add(staff1);
        National_Outings_Trip_Staff__c staff2 = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Co-Leader',
            Contact__c = contact2.Id
        );
        staffList.add(staff2);
        National_Outings_Trip_Staff__c staff3 = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Doctor',
            Contact__c = contact3.Id
        );
        staffList.add(staff3);
        National_Outings_Trip_Staff__c staff4 = new National_Outings_Trip_Staff__c(
            National_Outings_Trip__c = trip.Id,
            Role__c = 'Cook',
            Contact__c = contact4.Id
        );
        staffList.add(staff4);
        insert staffList;

        List<National_Outings_Trip_Vendor__c> vendorList = new List<National_Outings_Trip_Vendor__c>();
        National_Outings_Trip_Vendor__c vendor1 = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = vendorAccount1.Id,
            Type__c = 'Lodging'
        );
        vendorList.add(vendor1);
        National_Outings_Trip_Vendor__c vendor2 = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = vendorAccount2.Id,
            Type__c = 'Packer'
        );
        vendorList.add(vendor2);
        National_Outings_Trip_Vendor__c vendor3 = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = vendorAccount3.Id,
            Type__c = 'Rentals'
        );
        vendorList.add(vendor3);
        National_Outings_Trip_Vendor__c vendor4 = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = vendorAccount4.Id,
            Type__c = 'Shuttle'
        );
        vendorList.add(vendor4);
        National_Outings_Trip_Vendor__c vendor5 = new National_Outings_Trip_Vendor__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = vendorAccount5.Id,
            Type__c = 'Lodging'
        );
        vendorList.add(vendor5);
        insert vendorList;

        List<National_Outings_Trip_Agency__c> agencyList = new List<National_Outings_Trip_Agency__c>();
        National_Outings_Trip_Agency__c tripAgency1 = new National_Outings_Trip_Agency__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = agency1.Id
        );
        agencyList.add(tripAgency1);
        National_Outings_Trip_Agency__c tripAgency2 = new National_Outings_Trip_Agency__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = agency2.Id
        );
        agencyList.add(tripAgency2);
        National_Outings_Trip_Agency__c tripAgency3 = new National_Outings_Trip_Agency__c(
            National_Outings_Trip__c = trip.Id,
            Account__c = agency3.Id
        );
        agencyList.add(tripAgency3);
        insert agencyList;

        Id trip2Id = NatoutTripCopy.copy(trip.Id);
        National_Outings_Trip__c trip2 = new National_Outings_Trip__c(
            Id=trip2Id,
            Subcommittee__c = 'International'
        );
        update trip2;

        NatoutTripExportController ctl = new NatoutTripExportController();
        PageReference pageRef = Page.NatoutTripExport;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('trips', trip.Id + ',' + trip2.Id);
        List<NatoutTripExportController.ExportRow> rowList = ctl.getExportList();
    }
}
