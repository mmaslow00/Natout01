#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase3-01.xml --checkonly --testlevel RunSpecifiedTests --runtests ContentManagerServiceTest,NatoutTripServiceTest,NatoutEmailHandlerTest,NatoutTripCommentsControllerTest,NatoutTripCopyTest,NatoutTripTriggerHandlerTest,NatoutUserInfoTest,NatoutTripExportControllerTest --loglevel fatal
