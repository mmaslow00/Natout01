#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix1.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripTriggerHandlerTest,NatoutEmailHandlerTest --json --loglevel fatal
