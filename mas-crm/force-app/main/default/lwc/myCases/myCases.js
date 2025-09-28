import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getServiceCases from '@salesforce/apex/CustomerPortalController.getMyCases';

export default class MyCases extends NavigationMixin(LightningElement) {
    @track cases = [];
    @track filteredCases = [];
    @track statusFilter = '';
    @track priorityFilter = '';

    @wire(getServiceCases)
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data.map(caseRecord => ({
                ...caseRecord,
                caseUrl: `/lightning/r/Service_Case__c/${caseRecord.Id}/view`,
                createdDateFormatted: this.formatDate(caseRecord.CreatedDate),
                statusClass: this.getStatusClass(caseRecord.Status__c),
                statusBadge: this.getStatusBadge(caseRecord.Status__c),
                priorityBadge: this.getPriorityBadge(caseRecord.Priority__c),
                canSubmitFeedback: this.canSubmitFeedback(caseRecord.Status__c)
            }));
            this.filteredCases = this.cases;
        } else if (error) {
            this.showToast('Error', 'Failed to load cases: ' + error.body.message, 'error');
        }
    }

    handleStatusFilter(event) {
        this.statusFilter = event.target.value;
        this.applyFilters();
    }

    handlePriorityFilter(event) {
        this.priorityFilter = event.target.value;
        this.applyFilters();
    }

    applyFilters() {
        this.filteredCases = this.cases.filter(caseRecord => {
            const statusMatch = !this.statusFilter || caseRecord.Status__c === this.statusFilter;
            const priorityMatch = !this.priorityFilter || caseRecord.Priority__c === this.priorityFilter;
            return statusMatch && priorityMatch;
        });
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

    canSubmitFeedback(status) {
        return status === 'Resolved' || status === 'Closed';
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

    submitFeedback(event) {
        const caseId = event.target.dataset.caseId;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'feedback' },
            state: { caseId: caseId }
        });
    }

    createNewRequest() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Customer_Portal__c' }
        });
    }

    navigateToFeedback() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Feedback_Form__c' }
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
