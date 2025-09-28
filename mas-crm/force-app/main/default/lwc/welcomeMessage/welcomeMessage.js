import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class WelcomeMessage extends LightningElement {
    @track greeting = 'Hello';
    @track userName = '';
    @track message = 'Welcome to your CRM Dashboard!';

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        }
    }

    connectedCallback() {
        const hour = new Date().getHours();
        if (hour < 12) {
            this.greeting = 'Good Morning';
        } else if (hour < 17) {
            this.greeting = 'Good Afternoon';
        } else {
            this.greeting = 'Good Evening';
        }
    }
}
