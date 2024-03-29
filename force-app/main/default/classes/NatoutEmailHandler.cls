/*
Test coverage:
    NatoutEmailHandlerTest
    NatoutTripTriggerHandlerTest
*/
public without sharing class NatoutEmailHandler {
    public static final String staffEmailAddr = 'tony.rango@sierraclub.org';
    public static final String brochureEditorEmailAddr = 'outings.brochures@sierraclub.org';
    public static final String financeAssociateEmailAddr = 'tony.rango@sierraclub.org';
    public static final String landAgencyAssociateEmailAddr = 'outings.permits@sierraclub.org';
    public static final String marketingManagerEmailAddr = 'outings.publicity@sierraclub.org';
    public static final String safetyTeamEmailAddr = 'program.safety@sierraclub.org';

    public static List<TriggeredSendEmail__c> statusChanged(List<National_Outings_Trip__c> tripList, Map<Id, National_Outings_Trip__c> oldMap) {
        Map<Id, List<Recipient>> creatorMap = getCreators(tripList);
        Map<Id, List<Recipient>> approverMap = getApprovers(tripList);
        List<Recipient> budgetApproversList = getBudgetApprovers();
        Map<Id, String> budgetApproverNameMap = getBudgetApproverNameMap(tripList);

        List<TriggeredSendEmail__c> tseList = new List<TriggeredSendEmail__c>();

        for(National_Outings_Trip__c trip : tripList) {
            National_Outings_Trip__c prevTrip = oldMap.get(trip.Id);
            if((prevTrip.Status__c == 'Started' || prevTrip.Status__c == 'Returned')) {
                if(trip.Status__c == 'Submitted') {
                    List<Recipient> recipientList;
                    String msgText;
                    String subject;
                    if(trip.Subcommittee__c == 'International' && trip.Budget_Approved_Date__c == null) {
                        recipientList = budgetApproversList;
                        msgText = submitForBudgetApproval(trip.Id, trip.Subject_Title__c);
                        subject = 'Trip submission for ' + trip.Subject_Title__c + ' ready for budget review';
                        for(Recipient rcp : recipientList) {
                            tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                        }

                        recipientList = creatorMap.get(trip.Id);
                        msgText = notifyLdrBudgetApprovalSubmitted(trip.Id, trip.Subject_Title__c);
                        subject = 'Trip submission for ' + trip.Subject_Title__c + ' sent to budget reviewers';
                        for(Recipient rcp : recipientList) {
                            tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                        }
                    }
                    else {
                        recipientList = approverMap.get(trip.Id);
                        msgText = startedToSubmittedText(trip.Id, trip.Subject_Title__c);
                        subject = 'Trip submission for ' + trip.Subject_Title__c + ' ready for review';
                        for(Recipient rcp : recipientList) {
                            tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                        }
                    }
                }
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Approved by Chair') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText = submittedToApprovedByChairText(trip.Id, trip.Subject_Title__c, trip.Subcommittee__c);
                String subject = 'Trip submission for ' + trip.Subject_Title__c + ' approved by chair and/or collaborator';
                for(Recipient rcp : recipientList) {
                    tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                }
            }
            else if(prevTrip.Status__c == 'Approved by Chair' && trip.Status__c == 'Approved by Staff') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText = approvedByChairToApprovedByStaffText(trip.Id, trip.Subject_Title__c);
                String subject = 'Trip submission for ' + trip.Subject_Title__c + ' approved by staff';
                for(Recipient rcp : recipientList) {
                    tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                }
            }
            else if(prevTrip.Status__c == 'Submitted' && trip.Status__c == 'Returned') {
                List<Recipient> recipientList = creatorMap.get(trip.Id);
                String msgText;
                String subject = 'Trip submission for ' + trip.Subject_Title__c + ' returned';
                if(trip.Subcommittee__c == 'International' && trip.Budget_Approved_Date__c == null) {
                    String budgetApproverName = budgetApproverNameMap.get(trip.Id);
                    msgText = budgetReturnedText(trip.Id, trip.Subject_Title__c, budgetApproverName);
                }
                else {
                    msgText = submittedToReturnedText(trip.Id, trip.Subject_Title__c, trip.Subcommittee__c);
                }
                for(Recipient rcp : recipientList) {
                    tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                }
            }
        }
        return tseList;
    }

    public static List<TriggeredSendEmail__c> budgetApproved(List<National_Outings_Trip__c> tripList) {
        Map<Id, List<Recipient>> creatorMap = getCreators(tripList);
        Map<Id, List<Recipient>> approverMap = getApprovers(tripList);
        Map<Id, String> budgetApproverNameMap = getBudgetApproverNameMap(tripList);

        List<TriggeredSendEmail__c> tseList = new List<TriggeredSendEmail__c>();

        for(National_Outings_Trip__c trip : tripList) {
            String budgetApproverName = budgetApproverNameMap.get(trip.Id);

            List<Recipient> recipientList = creatorMap.get(trip.Id);
            String msgText = budgetApprovedToCreatorsText(trip.Id, trip.Subject_Title__c, budgetApproverName);
            String subject = 'Trip Budget Approved for ' + trip.Subject_Title__c;
            for(Recipient rcp : recipientList) {
                tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
            }

            recipientList = approverMap.get(trip.Id);
            msgText = budgetApprovedToChairsText(trip.Id, trip.Subject_Title__c, budgetApproverName);
            if(recipientList != null) {
                for(Recipient rcp : recipientList) {
                    tseList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msgText));
                }
            }
        }
        return tseList;
    }
    private static Map<Id, String> getBudgetApproverNameMap(List<National_Outings_Trip__c> tripList) {
        Map<Id, String> nameMap = new Map<Id, String>();
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip__c trip : tripList) {
            tripIds.add(trip.Id);
        }
        List<National_Outings_Trip__c> approverNameList = [
            SELECT Id, Budget_Approved_By__r.Name
            FROM National_Outings_Trip__c
            WHERE Id in :tripIds
        ];
        for(National_Outings_Trip__c trip : approverNameList) {
            nameMap.put(trip.Id, trip.Budget_Approved_By__r.Name);
        }
        return nameMap;
    }
    private static Map<Id, List<Recipient>> getCreators(List<National_Outings_Trip__c> tripList) {
        Set<Id> tripIds = new Set<Id>();
        for(National_Outings_Trip__c trip : tripList) {
            tripIds.add(trip.Id);
        }

        Map<Id, List<Recipient>> creatorMap = new Map<Id, List<Recipient>>();

        //Trip Leaders
        List<National_Outings_Trip_Staff__c> tripLeaderList = [
            SELECT National_Outings_Trip__c, Contact__c, Contact__r.Email
            FROM National_Outings_Trip_Staff__c
            WHERE 
                Role__c = 'Leader'
                AND National_Outings_Trip__c in :tripIds
        ];
        for(National_Outings_Trip_Staff__c staff : tripLeaderList) {
            List<Recipient> recipientList = creatorMap.get(staff.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(staff.Contact__c, staff.Contact__r.Email));
            creatorMap.put(staff.National_Outings_Trip__c, recipientList);
        }

        //Collaborators added by Leaders
        List<National_Outings_Trip_Collaborator__c> collabList = [
            SELECT
                National_Outings_Trip__c, 
                Contact__c,
                Contact__r.Email
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c in :tripIds AND Access__c = 'Edit'
        ];
        for(National_Outings_Trip_Collaborator__c collab : collabList) {
            List<Recipient> recipientList = creatorMap.get(collab.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(collab.Contact__c, collab.Contact__r.Email));
            creatorMap.put(collab.National_Outings_Trip__c, recipientList);
        }
        return creatorMap;
    }
    private static Map<Id, List<Recipient>> getApprovers(List<National_Outings_Trip__c> tripList) {
        Set<String> subcomms = new Set<String>();
        Set<Id> tripIds = new Set<Id>();

        for(National_Outings_Trip__c trip : tripList) {
            subcomms.add(trip.Subcommittee__c);
            tripIds.add(trip.Id);
        }

        //Subcommittee Officers with approval authority

        //First, create officerMap to find subcommittee officers by subcommittee name
        List<Leadership__c> subcommOfficerList = [
            SELECT
                Club_Entity__r.Name,
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Position_Status__c = 'Active' AND Leader_Position__r.Name IN ('Chair','Sub-comm Co-Chair','Vice Chair','Trip Submis. Collaborator')
                AND Club_Entity__r.Name in :subcomms
        ];
        Map<String, List<Recipient>> officerMap = new Map<String, List<Recipient>>();
        for(Leadership__c officer : subcommOfficerList) {
            List<Recipient> recipientList = officerMap.get(officer.Club_Entity__r.Name);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(officer.Contact__c, officer.Contact__r.Email));
            officerMap.put(officer.Club_Entity__r.Name, recipientList);
        }

        //Now create approverMap. Contains one entry for each trip, mapped to a list of recipients
        
        Map<Id, List<Recipient>> approverMap = new Map<Id, List<Recipient>>();

        //First add list of subcommittee officers for each trip
        for(National_Outings_Trip__c trip : tripList) {
            List<Recipient> recipientList = officerMap.get(trip.Subcommittee__c);
            if(recipientList != null) {
                approverMap.put(trip.Id, recipientList);
            }
        }

        //Next. add trip collaborators with approval authority for each trip
        //(collaborators granted approval authority for specific trips)
        List<National_Outings_Trip_Collaborator__c> collabList = [
            SELECT
                National_Outings_Trip__c, 
                Access__c,
                Contact__c,
                Contact__r.Email
            FROM National_Outings_Trip_Collaborator__c
            WHERE National_Outings_Trip__c in :tripIds AND Access__c = 'Approve'
        ];

        for(National_Outings_Trip_Collaborator__c collab : collabList) {
            List<Recipient> recipientList = approverMap.get(collab.National_Outings_Trip__c);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(collab.Contact__c, collab.Contact__r.Email));
            approverMap.put(collab.National_Outings_Trip__c, recipientList);
        }
        return approverMap;
    }
    private static List<Recipient> getBudgetApprovers() {
        List<Leadership__c> approverList = [
            SELECT
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Club_Entity__r.Name = 'International'
                AND Position_Status__c = 'Active' AND Leader_Position__r.Name = 'Trip Submission Approver'
        ];
        List<Recipient> rcpList = new List<Recipient>();
        for(Leadership__c ldr : approverList) {
            rcpList.add(new Recipient(ldr.Contact__c, ldr.Contact__r.Email));
        }
        return rcpList;
    }
    private static Map<Id, List<Recipient>> getSMPReviewers(List<National_Outings_Trip__c> tripList) {
        Set<String> subcomms = new Set<String>();
        for(National_Outings_Trip__c trip : tripList) {
            subcomms.add(trip.Subcommittee__c);
        }
        List<Leadership__c> reviewerList = [
            SELECT
                Club_Entity__r.Name,
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Position_Status__c = 'Active' AND Leader_Position__r.Code__c = 'SMP'
                AND Club_Entity__r.Name in :subcomms
        ];

        Map<String, List<Recipient>> smpMap = new Map<String, List<Recipient>>();
        for(Leadership__c reviewer : reviewerList) {
            List<Recipient> recipientList = smpMap.get(reviewer.Club_Entity__r.Name);
            if(recipientList == null) {
                recipientList = new List<Recipient>();
            }
            recipientList.add(new Recipient(reviewer.Contact__c, reviewer.Contact__r.Email));
            smpMap.put(reviewer.Club_Entity__r.Name, recipientList);
        }
        Map<Id, List<Recipient>> reviewerMap = new Map<Id, List<Recipient>>();
        for(National_Outings_Trip__c trip : tripList) {
            List<Recipient> recipientList = smpMap.get(trip.Subcommittee__c);
            if(recipientList != null) {
                reviewerMap.put(trip.Id, recipientList);
            }
        }
        return reviewerMap;
    }
    public static void notifySMPReviewers(String tripId) {
        National_Outings_Trip__c trip = [
            SELECT Id, Name, Subject_Title__c, Subcommittee__c FROM National_Outings_Trip__c WHERE Id = :tripId
        ];
        String subcomm = trip.Subcommittee__c;
        String msg =
            'A Safety Management Plan has been submitted for trip "' + trip.Subject_Title__c + '." ' +
            '<br/><br/>' +
            'Trip ' + trip.Subject_Title__c + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + trip.Id
            ;
        String subject = 'A Safety Management Plan has been submitted for trip ' + trip.Subject_Title__c;
        List<TriggeredSendEmail__c> sendList = new List<TriggeredSendEmail__c>();

        List<Leadership__c> reviewerList = [
            SELECT
                Contact__c, 
                Contact__r.Email
            FROM Leadership__c 
            WHERE
                Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                AND Position_Status__c = 'Active' AND Leader_Position__r.Code__c = 'SMP'
                AND Club_Entity__r.Name = :subcomm
        ];
        if(reviewerList.size() == 0) {
            reviewerList = [
                SELECT
                    Contact__c, 
                    Contact__r.Email
                FROM Leadership__c 
                WHERE
                    Club_Entity__r.Entity_Category__c = 'Outings' AND Club_Entity__r.Type__c = 'National Outing Subcomm' 
                    AND Position_Status__c = 'Active' AND Leader_Position__r.Name IN ('Chair','Sub-comm Co-Chair','Vice Chair','Trip Submis. Collaborator')
                    AND Club_Entity__r.Name = :subcomm
            ];
        }
        if(reviewerList.size() > 0) {
            List<Recipient> rcpList = new List<Recipient>();
            for(Leadership__c ldr : reviewerList) {
                rcpList.add(new Recipient(ldr.Contact__c, ldr.Contact__r.Email));
            }
            for(Recipient rcp : rcpList) {
                sendList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, msg));
            }
        }
        sendList.add(createTriggeredSend(null, safetyTeamEmailAddr, subject, msg));
        insert sendList;
    }
    private static String budgetApprovedToCreatorsText(String tripId, String tripTitle, String approverName) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been reviewed and approved by International subcommittee budget reviewer ' + approverName + '. ' +
            'Your trip submission will now be sent to the chair(s) for review. ' +
            'You will be notified once it has been accepted or if there are questions or changes required.' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String budgetApprovedToChairsText(String tripId, String tripTitle, String reviewerName) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been reviewed and approved by International subcommittee budget reviewer ' + reviewerName + '. ' +
            'If you’re satisfied with it, select "Approved by Chair" from the Status section at the top of the form, ' +
            'then hit the "Save" button, and it will be sent to staff for processing. ' +
            'You may also make adjustments or add comments at the end of the form before approving. ' +
            'If you’re not satisfied with it, add any questions or requested changes to the comments section at the bottom, ' +
            'and select "Returned" from the Status section at the top of the form, ' +
            'then hit the "Save" button, to return it to the trip leader for further edits.' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String startedToSubmittedText(String tripId, String tripTitle) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been submitted and is now ready for your review. ' +
            'If you’re satisfied with it, select "Approved by Chair" from the Status section at the top of the form, ' +
            'then hit the "Save" button, and it will be sent to staff for processing. ' +
            'You may also make adjustments or add comments at the end of the form before approving. ' +
            'If you’re not satisfied with it, add any questions or requested changes to the comments section at the bottom, ' +
            'and select "Returned" from the Status section at the top of the form, ' +
            'then hit the "Save" button, to return it to the trip leader for further edits.' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String submitForBudgetApproval(String tripId, String tripTitle) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been submitted and is now ready for your budget review. ' +
            'If you’re satisfied with it, click "Approve Budget", and it will be sent to the chair(s) for approval. ' +
            'You may also make adjustments or add comments at the end of the form before approving. ' + 
            'If you’re not satisfied with it, add any questions or requested changes to the comments section ' +
            'and click "Return Budget" to return it back to the trip leader for further edits. ' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String notifyLdrBudgetApprovalSubmitted(String tripId, String tripTitle) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been sent to the International subcommittee budget reviewers. ' +
            'You will be notified once it has been accepted or if there are questions or changes required.' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String submittedToApprovedByChairText(String tripId, String tripTitle, String subCommName) {
        String msg =
            'Trip submission for ' +
            tripTitle + ' ' +
            'has been approved the ' +
            subCommName + ' ' +
            'Subcommittee Chair and/or collaborators. ' +
            'Your trip will now be sent to staff for processing. ' +
            'You will be notified once the trip has been approved by staff or if there are questions or changes required. ' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }
    private static String approvedByChairToApprovedByStaffText(String tripId, String tripTitle) {
        String msg =
            'Trip submission for ' +
            tripTitle + ' ' +
            'has been approved by staff. ' +
            'If there are any changes to your trip now that it is in the system, ' +
            'please notify tony.rango@sierraclub.org and copy your subcommittee chair so that all parties are in the loop. ' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
        ;
        return msg;
    }
    private static String submittedToReturnedText(String tripId, String tripTitle, String subCommName) {
        String msg = 
            'Trip Submission for ' + tripTitle + ' ' +
            'has been reviewed by the ' + subCommName + ' ' +
            'Subcommittee Chair, collaborators, and/or staff ' +
            'and is being returned to you with questions or requested changes. ' +
            'Please review the comments at the end of the trip submission form for an explanation of why it was returned. ' +
            'Once you’ve addressed these questions or changes, you may resubmit, with comments if necessary. ' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
        ;
        return msg;
    }
    private static String budgetReturnedText(String tripId, String tripTitle, String reviewerName) {
        String msg = 
            'Trip "' +
            tripTitle + '" ' +
            'has been reviewed by International subcommittee budget reviewer ' +
            reviewerName +
            ' and is being returned to you with questions and/or requested changes. ' +
            'Please review the comments at the end of the trip submission form for an explanation. ' +
            'Once you’ve addressed these questions or changes, you may resubmit, with comments if necessary.' +
            '<br/><br/>' +
            'Trip ' + tripTitle + ' can be found at https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId
            ;
        return msg;
    }

    public static void notifyOfComments(List<National_Outings_Trip_Comments__c> commentsList) {
        Set<Id> tripIds = new Set<Id>();
        Set<Id> commentsIds = new Set<Id>();
        for(National_Outings_Trip_Comments__c comments : commentsList) {
            tripIds.add(comments.National_Outings_Trip__c);
            commentsIds.add(comments.Id);
        }
        List<National_Outings_Trip__c> tripList = [
            SELECT Id, Name, Subject_Title__c, Subcommittee__c FROM National_Outings_Trip__c WHERE Id in :tripIds
        ];
        Map<Id, National_Outings_Trip__c> tripMap = new Map<Id, National_Outings_Trip__c>(tripList);
        Map<Id, List<Recipient>> creatorMap = getCreators(tripList);
        Map<Id, List<Recipient>> approverMap = getApprovers(tripList);
        Map<Id, List<Recipient>> reviewerMap = getSMPReviewers(tripList);

        List<TriggeredSendEmail__c> sendList = new List<TriggeredSendEmail__c>();
        List<National_Outings_Trip_Comments_Recip__c> commentsRecipList = new List<National_Outings_Trip_Comments_Recip__c>();
        List<National_Outings_Trip_Comments__c> commentsWithCreatorList = [
            SELECT
                Id, 
                National_Outings_Trip__c, 
                Comments__c,
                Notify_Creators__c,
                Notify_Approvers__c,
                Notify_Staff__c,
                Notify_Brochure_Editor__c,
                Notify_Finance__c,
                Notify_Land_Agency__c,
                Notify_Marketing__c,
                Notify_Safety__c,
                Notify_SMP_Reviewer__c,
                CreatedBy.Name
            FROM National_Outings_Trip_Comments__c
            WHERE Id in :commentsIds
        ];
        for(National_Outings_Trip_Comments__c comments : commentsWithCreatorList) {
            National_Outings_Trip__c trip = tripMap.get(comments.National_Outings_Trip__c);
            String subject = 'New Comment for Trip ' + trip.Subject_Title__c + ' from ' + comments.CreatedBy.Name;

            String link = 'https://campfire.sierraclub.org/NatoutTripDetail?id=' + comments.National_Outings_Trip__c;
            String commentsText = comments.Comments__c + '<br/><br/>Trip ' + trip.Subject_Title__c + ' can be found at ' + link;

            if(comments.Notify_Creators__c) {
                List<Recipient> recipientList = creatorMap.get(comments.National_Outings_Trip__c);
                for(Recipient rcp : recipientList) {
                    sendList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, commentsText));
                    commentsRecipList.add(
                        new National_Outings_Trip_Comments_Recip__c(
                            Contact__c = rcp.contactId,
                            Email__c = rcp.emailAddr,
                            National_Outings_Trip_Comments__c = comments.Id
                        )
                    );
                }
            }
            if(comments.Notify_Approvers__c) {
                List<Recipient> recipientList = approverMap.get(comments.National_Outings_Trip__c);
                for(Recipient rcp : recipientList) {
                    sendList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, commentsText));
                    commentsRecipList.add(
                        new National_Outings_Trip_Comments_Recip__c(
                            Contact__c = rcp.contactId,
                            Email__c = rcp.emailAddr,
                            National_Outings_Trip_Comments__c = comments.Id
                        )
                    );
                }
            }
            if(comments.Notify_Staff__c) {
                sendList.add(createTriggeredSend(null, staffEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = staffEmailAddr,
                        Staff_Position__c = 'Program Director',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_Brochure_Editor__c) {
                sendList.add(createTriggeredSend(null, brochureEditorEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = brochureEditorEmailAddr,
                        Staff_Position__c = 'Brochure Editor',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_Finance__c) {
                sendList.add(createTriggeredSend(null, financeAssociateEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = financeAssociateEmailAddr,
                        Staff_Position__c = 'Finance Associate',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_Land_Agency__c) {
                sendList.add(createTriggeredSend(null, landAgencyAssociateEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = landAgencyAssociateEmailAddr,
                        Staff_Position__c = 'Land Agency Associate',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_Marketing__c) {
                sendList.add(createTriggeredSend(null, marketingManagerEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = marketingManagerEmailAddr,
                        Staff_Position__c = 'Marketing Manager',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_Safety__c) {
                sendList.add(createTriggeredSend(null, safetyTeamEmailAddr, subject, commentsText));
                commentsRecipList.add(
                    new National_Outings_Trip_Comments_Recip__c(
                        Email__c = safetyTeamEmailAddr,
                        Staff_Position__c = 'Program Safety Team',
                        National_Outings_Trip_Comments__c = comments.Id
                    )
                );
            }
            if(comments.Notify_SMP_Reviewer__c) {
                List<Recipient> recipientList = reviewerMap.get(comments.National_Outings_Trip__c);
                if(recipientList == null && comments.Notify_Approvers__c == false) {
                    recipientList = approverMap.get(comments.National_Outings_Trip__c);
                }
                if(recipientList != null) {
                    for(Recipient rcp : recipientList) {
                        sendList.add(createTriggeredSend(rcp.contactId, rcp.emailAddr, subject, commentsText));
                        commentsRecipList.add(
                            new National_Outings_Trip_Comments_Recip__c(
                                Contact__c = rcp.contactId,
                                Email__c = rcp.emailAddr,
                                National_Outings_Trip_Comments__c = comments.Id
                            )
                        );
                    }
                }
            }
        }
        insert sendList;
        insert commentsRecipList;
    }
    @AuraEnabled 
    public static Datetime submitBrochure(String tripId) {
        National_Outings_Trip__c trip = [
            SELECT Subject_Title__c FROM National_Outings_Trip__c
            WHERE Id = :tripId
        ];
        Datetime now = System.now();
        if(trip != null) {
            String contactId = NatoutUserInfo.getContactId();
            Contact ctct = [
                SELECT Name, Email FROM Contact where Id=:contactId
            ];
            String subject = 'Brochure Submitted for ' + trip.Subject_Title__c;
            String msgText = 
                ctct.Name + 
                ' (<a href="' + 'mailto:' + ctct.Email + '?subject=' + subject + '">' +
                ctct.Email + '</a>)' +
                ' has submitted the brochure for ' +
                trip.Subject_Title__c +
                '.<br/><br/>' +
                'Trip ' + trip.Subject_Title__c + ' can be found at <a href="https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId + '">' +
                'https://campfire.sierraclub.org/NatoutTripDetail?id=' + tripId + '</a>'
            ;
            List<TriggeredSendEmail__c> sendList = new List<TriggeredSendEmail__c>();
            sendList.add(createTriggeredSend(null, brochureEditorEmailAddr, subject, msgText));
            String intro = 'The following message has been sent to ' + brochureEditorEmailAddr + '.<br/><br/>';
            sendList.add(createTriggeredSend(contactId, ctct.Email, subject, intro + msgText));
            insert sendList;

            National_Outings_Trip__c trip2Update = new National_Outings_Trip__c(
                Id = tripId,
                Brochure_Submitted_Date__c = now
            );
            update trip2Update;
        }
        return now;
    }

    public static TriggeredSendEmail__c createTriggeredSend(Id contactId, String emailAddr, String subject, String msg) {
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('To');
        gen.writeStartObject();
        gen.writeStringField('Address', emailAddr);
        gen.writeStringField('SubscriberKey', contactId == null ? emailAddr : contactId);
        gen.writeFieldName('ContactAttributes');
        gen.writeStartObject();
        gen.writeFieldName('SubscriberAttributes');
        gen.writeStartObject();
        gen.writeStringField('Subject', subject);
        gen.writeStringField('TEXT__Body', msg);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.close();
        
        TriggeredSendEmail__c triggeredSend = new TriggeredSendEmail__c (
            Email__c = emailAddr,
            SubscriberKey__c = contactId,
            RequestBody__c = gen.getAsString(),
            SendId__c = 'nat-trip-sub'
        );
        return triggeredSend;
    }
    private class Recipient {
        public recipient(Id contactId, String emailAddr) {
            this.contactId = contactId;
            this.emailAddr = emailAddr;
        }
        String emailAddr;
        Id contactId;
    }
}