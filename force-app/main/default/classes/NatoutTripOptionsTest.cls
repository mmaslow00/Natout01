@isTest
public with sharing class NatoutTripOptionsTest {
    static testMethod void myUnitTest() {
        NatoutTripOptions.TripOptions tripOptions = NatoutTripOptions.getOptions();
        NatoutTripOptions.VendorOptions vendorOptions = NatoutTripOptions.getVendorOptions();
    }
}
