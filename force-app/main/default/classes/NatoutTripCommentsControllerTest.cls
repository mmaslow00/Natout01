@isTest
public with sharing class NatoutTripCommentsControllerTest {
    static testMethod void myUnitTest() {
        National_Outings_Trip__c trip = new National_Outings_Trip__c(
                Name = 'Test Trip',
                Subcommittee__c = 'Knapsack',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today() + 2
            );
            insert trip;
         
            National_Outings_Trip_Comments__c comment = new National_Outings_Trip_Comments__c(
                National_Outings_Trip__c = trip.Id,
                Comments__c = 'This is a Test'
            );
            insert comment;
            List<National_Outings_Trip_Comments__c> commentsList = NatoutTripCommentsController.getCommentsList(trip.Id);
            System.assertEquals(1, commentsList.size());
        }
    }
