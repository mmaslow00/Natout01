import { LightningElement, api } from 'lwc';

export default class LocationFinder extends LightningElement {
    @api latLng = {};

    get mapPageUrl() {
        let lastSlash = window.location.pathname.lastIndexOf('/');
        let pathStart = window.location.pathname.substring(0,lastSlash + 1);
        let retUrl = window.location.origin + pathStart + 'LocationFinderLightning';
        if(this.latLng.latitude && this.latLng.longitude) {
            retUrl += '?location=' + this.latLng.latitude + ',' + this.latLng.longitude;
        }
        return retUrl;
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