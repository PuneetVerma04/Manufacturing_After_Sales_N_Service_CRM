import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class WelcomePage extends NavigationMixin(LightningElement) {
    @track userName = 'Customer';

    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        } else if (error) {
            this.userName = 'Customer';
        }
    }

    navigateToRaiseIssue() {
        // Example: navigate to product registration page
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Customer_Portal__c' }
        });
    }

    navigateToCases() {
        // Example: navigate to My Cases page
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Customer_Cases__c' }
        });
    }

    navigateToFeedback() {
        // Example: navigate to Feedback page
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Feedback__c' }
        });
    }
}
