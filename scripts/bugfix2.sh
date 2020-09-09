#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix2.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutUserInfoTest,NatoutEmailHandlerTest --json --loglevel fatal
