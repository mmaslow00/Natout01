#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase3-01.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripServiceTest,NatoutEmailHandlerTest,NatoutTripCommentsControllerTest,NatoutTripCopyTest,NatoutTripTriggerHandlerTest,NatoutUserInfoTest,NatoutTripExportControllerTest --loglevel fatal
