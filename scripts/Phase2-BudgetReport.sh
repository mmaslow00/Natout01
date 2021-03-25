#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase2-BudgetReport.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripBudgetControllerTest,NatoutTripAgenciesControllerTest --json --loglevel fatal
