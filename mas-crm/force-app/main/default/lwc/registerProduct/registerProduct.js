import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProductCatalog from '@salesforce/apex/CustomerPortalController.getProductCatalog';
import getLoggedInUserContact from '@salesforce/apex/CustomerPortalController.getLoggedInUserContact';
import createRegisteredProduct from '@salesforce/apex/CustomerPortalController.createRegisteredProduct';

export default class RegisteredProductForm extends LightningElement {
    @track serviceRequest = {
        name: '',
        serialNumber: '',
        purchaseDate: '',
        amcExpiry: '',
        warrantyExpiry: '',
        defective: false,
        productId: '',
        contactId: ''
    };

    @track products = [];

    connectedCallback() {
        this.fetchLoggedInUserContact();
    }

    fetchLoggedInUserContact() {
        getLoggedInUserContact()
            .then(contact => {
                if (contact) {
                    this.serviceRequest.contactId = contact.Id;
                }
            })
            .catch(error => {
                this.showToast('Error', 'Failed to fetch contact: ' + error.body.message, 'error');
            });
    }

    @wire(getProductCatalog)
        wiredProducts({ error, data }) {
            if (data) {
                // Map to lightning-combobox format { label, value }
                this.products = data.map(prod => ({
                    label: prod.Name + (prod.ProductCode ? ` (${prod.ProductCode})` : ''),
                    value: prod.Id
                }));
                console.log('Products loaded:', this.products); // Debugging line
            }else if (error) {
                console.error('Error loading product catalog:', error); // Debugging line
                this.showToast('Error', 'Failed to load product catalog: ' + error.body.message, 'error');
            }
}

    handleInputChange(event) {
        const field = event.target.dataset.field;
        if (field) {
            this.serviceRequest[field] = event.target.value;
        }
    }

    handleCheckboxChange(event) {
        this.serviceRequest.defective = event.target.checked;
    }

    handleSubmit() {
    // Check required fields
    if (!this.serviceRequest.name ||
        !this.serviceRequest.productId ||
        !this.serviceRequest.serialNumber ||
        !this.serviceRequest.purchaseDate ||
        !this.serviceRequest.contactId) {
        this.showToast('Error', 'Please fill all required fields', 'error');
        return;
    }

    // Prepare record for Apex
    const record = {
        Name: this.serviceRequest.name,
        Serial_Number__c: this.serviceRequest.serialNumber,
        Purchase_Date__c: this.serviceRequest.purchaseDate,
        AMC_Expiry__c: this.serviceRequest.amcExpiry,
        Warranty_Expiry__c: this.serviceRequest.warrantyExpiry,
        Defective__c: this.serviceRequest.defective,
        Product__c: this.serviceRequest.productId,
        Contact__c: this.serviceRequest.contactId,
        OwnerId: this.serviceRequest.contactId // optional if needed
    };

    createRegisteredProduct({ registeredProduct: record })
        .then(() => {
            this.showToast('Success', 'Product registered successfully!', 'success');
            this.resetForm();
        })
        .catch(error => {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast('Error', 'Failed to register product: ' + message, 'error');
        });
}

}
