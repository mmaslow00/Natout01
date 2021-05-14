trigger NatoutTripCommentsTrigger on National_Outings_Trip_Comments__c (after insert) {
    NatoutEmailHandler.notifyOfComments(Trigger.new);
}