@isTest
public with sharing class NatoutTripServiceTest {
    static Id eventId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Events').getRecordTypeId();
    static Id accountHouseholdTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    static Id contactHouseholdTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Household').getRecordTypeId();
    static testMethod void testTripPrice() {
    	Club_Entity__c clubEntity = new Club_Entity__c(
    		Name = 'Test Entity'
    	);
    	insert clubEntity;
		Campaign camp = new Campaign(
			RecordTypeId = eventId,
			Name = 'Test',
			External_ID__c = 'Test',
			Event_Name__c = 'Test',
			Start_Date__c = System.today(),
			Start_Time__c = '8:30 AM',
			Time_Zone__c = 'Pacific',
			Club_Entity__c = clubEntity.Id,
            Trip_Price__c = 1000
		);
		ClubEventTriggerHandler.Testing = true;
        insert camp;
        Decimal price = NatoutTripService.getTripPrice('Test');
        System.assertEquals(1000, price);
        camp.Trip_Price__c = null;
        update camp;
        price = NatoutTripService.getTripPrice('Test');
        System.assertEquals(0, price);
    }

    static testMethod void testSatPhoneAddress() {
		Account householdAccount = new Account(
            Name='Account1',
            RecordTypeId = accountHouseholdTypeId
        );
        insert householdAccount;
        Contact contact1 = new Contact(
            AccountId = householdAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact1',
            Email = 'test1.contact1@abc.com',
            MailingStreet = '1234 Main St',
            MailingCity = 'Somewhere',
            MailingState = 'CA',
            MailingPostalCode = '12345',
            RecordTypeId = contactHouseholdTypeId
        );
        insert contact1;
        User_Lookups__c lookup = new User_Lookups__c(
            Contact__c = contact1.Id,
            User__c = UserInfo.getUserId()
        );
        insert lookup;

        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Status__c = 'Started'
        );
        insert trip;
        Id tripId = trip.Id;

        NatoutTripService.ShipTo shipTo = NatoutTripService.getSatPhoneAddr(tripId);
    }
    static testMethod void testBudgetApproval() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Status__c = 'Started'
        );
        insert trip;
        Id tripId = trip.Id;
        NatoutTripService.BudgetApproval appr = NatoutTripService.approveBudget(tripId);
    }
    static testMethod void testBudgetReturn() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
            Name = 'Test Trip',
            Subcommittee__c = 'Knapsack',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today() + 2,
            Status__c = 'Started'
        );
        insert trip;
        Id tripId = trip.Id;
        NatoutTripService.BudgetApproval appr = NatoutTripService.returnBudget(tripId);
    }
}
