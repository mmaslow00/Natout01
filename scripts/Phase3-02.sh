#!/bin/bash
sfdx force:source:deploy --manifest manifest\\FixBP.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripBudgetExportControllerTest,NatoutTripBudgetReportControllerTest,NatoutTripExportControllerTest,NatoutTripLinksControllerTest,NatoutTripListControllerTest --loglevel fatal
