#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix9.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripBudgetReportControllerTest,NatoutTripCopyTest --json --loglevel fatal > deployResults.json
