#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix8.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutEmailHandlerTest --json --loglevel fatal > deployResults.json
