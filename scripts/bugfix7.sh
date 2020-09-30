#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix7.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripExportControllerTest,NatoutTripListControllerTest --json --loglevel fatal > deployResults.json
