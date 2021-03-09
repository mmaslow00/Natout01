#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase2-01.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripItineraryControllerTest,NatoutTripBudgetControllerTest,NatoutEmailHandlerTest,NatoutTripPostTripReportTest --json --loglevel fatal
