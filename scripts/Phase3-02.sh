#!/bin/bash
sfdx force:source:deploy --manifest manifest\\Phase3-02.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutTripFilesServiceTest,NatoutEmailHandlerTest,NatoutTripTriggerHandlerTest,NatoutTripCopyTest,NatoutTripServiceTest --loglevel fatal
