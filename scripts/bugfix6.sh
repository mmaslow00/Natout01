#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix6.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutUserInfoTest --json --loglevel fatal
