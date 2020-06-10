import { LightningElement, track, api } from 'lwc';
import INFOBUBBLEICON from '@salesforce/resourceUrl/InfoBubbleIcon';

export default class Tooltip extends LightningElement {
    @api text;
    infoBubbleIcon = INFOBUBBLEICON;
}