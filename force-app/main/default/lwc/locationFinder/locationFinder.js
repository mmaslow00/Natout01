import { LightningElement, api } from 'lwc';

export default class LocationFinder extends LightningElement {
    @api latLng = {};

    get mapPageUrl() {
        let baseUrl = window.location.protocol + '//' + window.location.hostname + '/' + window.location.pathname.split('/')[1];
        baseUrl += '/LocationFinderLightning';
        if(this.latLng.latitude && this.latLng.longitude) {
            baseUrl += '?location=' + this.latLng.latitude + ',' + this.latLng.longitude;
        }
        return baseUrl;
    }
    connectedCallback() {
        window.addEventListener("message", function(event) {
            event.preventDefault();
            let latLng = JSON.parse(event.data);
            this.latLng = latLng; //When executing, "this" is pointer to window
        });
    }
    setLocation(e) {
        e.preventDefault();
        const locationSelectedEvent = new CustomEvent("locationselected",
            {detail: window.latLng}
        );
        this.dispatchEvent(locationSelectedEvent);
    }
    cancelLocation(e) {
        e.preventDefault();
        const cancelLocationEvent = new CustomEvent("cancellocation");
        this.dispatchEvent(cancelLocationEvent);
    }
}