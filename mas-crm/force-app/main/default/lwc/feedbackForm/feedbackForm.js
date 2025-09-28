import { LightningElement, track } from 'lwc';
import validateAndCreateFeedback from '@salesforce/apex/FeedbackController.validateAndCreateFeedback';


export default class FeedbackForm extends LightningElement {
    get isSubmitDisabled() {
        return !this.serviceCaseId || !this.customerName || !this.customerEmail || !this.rating || this.isLoading;
    }
    @track serviceCaseId = '';
    @track customerName = '';
    @track customerEmail = '';
    @track rating = '';
    @track comments = '';
    @track isLoading = false;
    @track message = '';
    @track messageType = '';
    @track messageClass = '';
    ratingOptions = [
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' }
    ];


    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    handleRatingChange(event) {
        this.rating = event.target.value;
    }

    async submitFeedback() {
        if (!this.serviceCaseId || !this.customerName || !this.customerEmail || !this.rating) {
            this.showMessage('Please fill in all required fields', 'error');
            return;
        }
        this.isLoading = true;
        try {
            const result = await validateAndCreateFeedback({
                serviceCaseId: this.serviceCaseId,
                customerName: this.customerName,
                customerEmail: this.customerEmail,
                rating: parseInt(this.rating, 10),
                comments: this.comments
            });
            this.showMessage('Feedback submitted successfully! Thank you for your input.', 'success');
            this.resetForm();
        } catch (error) {
            this.showMessage(error.body && error.body.message ? error.body.message : 'Submission failed.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    resetForm() {
        this.serviceCaseId = '';
        this.customerName = '';
        this.customerEmail = '';
        this.rating = '';
        this.comments = '';
    }

    showMessage(message, type) {
        this.message = message;
        this.messageType = type;
        this.messageClass = type === 'success' ? 'slds-notify slds-notify_success' : 'slds-notify slds-notify_alert';
        setTimeout(() => {
            this.message = '';
        }, 5000);
    }
}
