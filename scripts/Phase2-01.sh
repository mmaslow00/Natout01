#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase2-01.xml --checkonly --testlevel RunSpecifiedTests --runtests ContentManagerServiceTest,FileUploadServiceTest,NatoutTripTriggerHandlerTest,NatoutTripItineraryControllerTest,NatoutTripBudgetControllerTest,NatoutEmailHandlerTest,NatoutTripPostTripReportTest --json --loglevel fatal
