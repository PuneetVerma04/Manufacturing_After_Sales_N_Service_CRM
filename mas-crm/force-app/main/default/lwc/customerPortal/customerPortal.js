import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRegisteredProducts from '@salesforce/apex/CustomerPortalController.getProductCatalog';
import createServiceRequest from '@salesforce/apex/CustomerPortalController.createServiceRequest';
import getLoggedInUserContact from '@salesforce/apex/CustomerPortalController.getLoggedInUserContact';

export default class CustomerPortal extends LightningElement {
    @track serviceRequest = {
        customerName: '',
        customerEmail: '',
        contactId: '',
        subject: '',
        registeredProductId: '',
        description: ''
    };

    @track products = [];

    connectedCallback() {
        this.fetchLoggedInUserContact();
    }

    // Auto-fill contact info
    fetchLoggedInUserContact() {
        getLoggedInUserContact()
            .then(contact => {
                if (contact) {
                    this.serviceRequest.customerName = contact.Name;
                    this.serviceRequest.customerEmail = contact.Email;
                    this.serviceRequest.contactId = contact.Id;
                }
            })
            .catch(error => {
                this.showToast('Error fetching contact info: ' + (error.body?.message || error.message), 'error');
            });
    }

    // Load registered products
    @wire(getRegisteredProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data.map(prod => ({
                label: prod.Name + ' (ID: ' + prod.Product_ID__c + ')',
                value: prod.Id
            }));
        } else if (error) {
            this.showToast('Error loading products: ' + (error.body?.message || error.message), 'error');
        }
    }

    // Update local state on input change
    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.serviceRequest = { ...this.serviceRequest, [field]: event.target.value };
    }

    // Submit service request
    handleSubmit() {
        const { customerName, customerEmail, contactId, subject, registeredProductId, description } = this.serviceRequest;

        if (!subject || !registeredProductId) {
            this.showToast('Please fill in all required fields', 'error');
            return;
        }

        createServiceRequest({ 
            customerName, 
            customerEmail, 
            contactId,
            subject, 
            registeredProductId, 
            description 
        })
        .then(caseId => {
            this.showToast('Service Request submitted successfully! Case Id: ' + caseId, 'success');
            this.resetForm();
        })
        .catch(error => {
            this.showToast('Error creating service request: ' + (error.body?.message || error.message), 'error');
        });
    }

    resetForm() {
        this.serviceRequest.subject = '';
        this.serviceRequest.registeredProductId = '';
        this.serviceRequest.description = '';
    }

    showToast(message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: variant === 'success' ? 'Success' : 'Error',
                message,
                variant
            })
        );
    }
}
