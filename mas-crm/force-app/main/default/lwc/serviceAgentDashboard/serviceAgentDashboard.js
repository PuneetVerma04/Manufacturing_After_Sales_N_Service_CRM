import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getServiceAgentStats from '@salesforce/apex/ServiceAgentController.getServiceAgentStats';
import getRecentCases from '@salesforce/apex/ServiceAgentController.getRecentCases';
import getRecentFeedback from '@salesforce/apex/ServiceAgentController.getRecentFeedback';
import getProductStatus from '@salesforce/apex/ServiceAgentController.getProductStatus';

export default class ServiceAgentDashboard extends NavigationMixin(LightningElement) {
    @track totalCases = 0;
    @track openCases = 0;
    @track slaBreached = 0;
    @track avgRating = 0;
    @track recentCases = [];
    @track recentFeedback = [];
    @track productStatus = [];
    @track showRecentCases = true;
    @track showFeedback = false;
    @track showProducts = false;

    @wire(getServiceAgentStats)
    wiredStats({ error, data }) {
        if (data) {
            this.totalCases = data.totalCases || 0;
            this.openCases = data.openCases || 0;
            this.slaBreached = data.slaBreached || 0;
            this.avgRating = data.avgRating || 0;
        } else if (error) {
            this.showToast('Error', 'Failed to load dashboard stats: ' + error.body.message, 'error');
        }
    }

    @wire(getRecentCases)
    wiredRecentCases({ error, data }) {
        if (data) {
            this.recentCases = data.map(caseItem => ({
                ...caseItem,
                caseUrl: `/lightning/r/Service_Case__c/${caseItem.Id}/view`,
                createdDateFormatted: this.formatDate(caseItem.CreatedDate),
                statusClass: this.getStatusClass(caseItem.Status__c),
                statusBadge: this.getStatusBadge(caseItem.Status__c),
                priorityBadge: this.getPriorityBadge(caseItem.Priority__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load recent cases: ' + error.body.message, 'error');
        }
    }

    @wire(getRecentFeedback)
    wiredRecentFeedback({ error, data }) {
        if (data) {
            this.recentFeedback = data.map(feedback => ({
                ...feedback,
                caseUrl: `/lightning/r/Service_Case__c/${feedback.Service_Case__c}/view`,
                createdDateFormatted: this.formatDate(feedback.CreatedDate),
                ratingClass: this.getRatingClass(feedback.Rating__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load recent feedback: ' + error.body.message, 'error');
        }
    }

    @wire(getProductStatus)
    wiredProductStatus({ error, data }) {
        if (data) {
            this.productStatus = data.map(product => ({
                ...product,
                warrantyStatus: this.getWarrantyStatus(product.Warranty_Expiry__c),
                amcStatus: this.getAmcStatus(product.AMC_Expiry__c),
                warrantyClass: this.getWarrantyClass(product.Warranty_Expiry__c),
                amcClass: this.getAmcClass(product.AMC_Expiry__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load product status: ' + error.body.message, 'error');
        }
    }

    switchTab(event) {
        event.preventDefault();
        const tabName = event.target.dataset.tab;
        
        // Reset all tabs
        this.showRecentCases = false;
        this.showFeedback = false;
        this.showProducts = false;
        
        // Show selected tab
        switch (tabName) {
            case 'recent-cases':
                this.showRecentCases = true;
                break;
            case 'feedback':
                this.showFeedback = true;
                break;
            case 'products':
                this.showProducts = true;
                break;
        }
    }

    formatDate(dateString) {
        if (!dateString) return 'N/A';
        return new Date(dateString).toLocaleDateString();
    }

    getStatusClass(status) {
        switch (status) {
            case 'New': return 'slds-theme_info';
            case 'In Progress': return 'slds-theme_warning';
            case 'Resolved': return 'slds-theme_success';
            case 'Closed': return 'slds-theme_shade';
            default: return '';
        }
    }

    getStatusBadge(status) {
        switch (status) {
            case 'New': return 'slds-badge slds-badge_lightest';
            case 'In Progress': return 'slds-badge slds-badge_warning';
            case 'Resolved': return 'slds-badge slds-badge_success';
            case 'Closed': return 'slds-badge slds-badge_inverse';
            default: return 'slds-badge';
        }
    }

    getPriorityBadge(priority) {
        switch (priority) {
            case 'High': return 'slds-badge slds-badge_destructive';
            case 'Medium': return 'slds-badge slds-badge_warning';
            case 'Low': return 'slds-badge slds-badge_success';
            default: return 'slds-badge';
        }
    }

    getRatingClass(rating) {
        if (rating >= 4) return 'slds-badge slds-badge_success';
        if (rating >= 3) return 'slds-badge slds-badge_warning';
        return 'slds-badge slds-badge_destructive';
    }

    getWarrantyStatus(warrantyDate) {
        if (!warrantyDate) return 'Unknown';
        const today = new Date();
        const warranty = new Date(warrantyDate);
        return warranty >= today ? 'Active' : 'Expired';
    }

    getAmcStatus(amcDate) {
        if (!amcDate) return 'None';
        const today = new Date();
        const amc = new Date(amcDate);
        return amc >= today ? 'Active' : 'Expired';
    }

    getWarrantyClass(warrantyDate) {
        const status = this.getWarrantyStatus(warrantyDate);
        return status === 'Active' ? 'slds-badge slds-badge_success' : 'slds-badge slds-badge_destructive';
    }

    getAmcClass(amcDate) {
        const status = this.getAmcStatus(amcDate);
        if (status === 'None') return 'slds-badge slds-badge_lightest';
        return status === 'Active' ? 'slds-badge slds-badge_success' : 'slds-badge slds-badge_destructive';
    }

    createNewCase() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Service_Case__c',
                actionName: 'new'
            }
        });
    }

    viewAllCases() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Service_Case__c',
                actionName: 'list'
            }
        });
    }

    productLookup() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Registered_Product__c',
                actionName: 'list'
            }
        });
    }

    editCase(event) {
        const caseId = event.target.dataset.caseId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'edit'
            }
        });
    }

    viewCase(event) {
        const caseId = event.target.dataset.caseId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view'
            }
        });
    }

    viewProduct(event) {
        const productId = event.target.dataset.productId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
