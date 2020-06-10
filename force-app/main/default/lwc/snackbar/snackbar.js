import { LightningElement, track, api } from 'lwc';

export default class Snackbar extends LightningElement {
    @track messageHeader;
    @track messageText;
    @api show(type, header, text) {
        let div = this.template.querySelector('.snackbar');

        if(type === 'success') {
            div.classList.add('success');
        }
        else if(type === 'failure') {
            div.classList.add('failure');
        }
        this.messageHeader = header;
        this.messageText = text;
        div.classList.add('show');
        setTimeout(function() { 
            div.classList.remove('show'); 
            div.classList.remove('success'); 
            div.classList.remove('failure'); 
        }, 4000);    
    }
}