#!/bin/bash
sfdx force:source:deploy --manifest manifest\\bugfix5.xml --checkonly --testlevel RunSpecifiedTests --runtests NatoutUserInfoTest --json --loglevel fatal
