import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEngineerInfo from '@salesforce/apex/EngineerDashboardController.getEngineerInfo';
import getAssignedJobs from '@salesforce/apex/EngineerDashboardController.getAssignedJobs';
import getDispatchJobs from '@salesforce/apex/EngineerDashboardController.getDispatchJobs';
import updateJobStatus from '@salesforce/apex/EngineerDashboardController.updateJobStatus';

export default class EngineerDashboard extends LightningElement {
    @track engineerInfo = null;
    @track assignedJobs = [];
    @track dispatchJobs = [];
    @track isLoading = false;

    // Modal state
    @track showModal = false;
    @track selectedJobId;
    @track selectedJobStatus;
    @track nextStatus;
    @track feedback = '';

    @wire(getEngineerInfo)
    wiredEngineerInfo({ error, data }) {
        if (data) {
            this.engineerInfo = data;
        } else if (error) {
            this.showToast('Error', 'Failed to load engineer info: ' + error.body.message, 'error');
        }
    }

    @wire(getAssignedJobs)
    wiredAssignedJobs({ error, data }) {
        if (data) {
            this.assignedJobs = data.map(job => ({
                ...job,
                caseUrl: `/lightning/r/Service_Case__c/${job.Id}/view`,
                slaDeadlineFormatted: this.formatDateTime(job.SLA_Deadline__c),
                timeRemaining: this.calculateTimeRemaining(job.SLA_Deadline__c),
                priorityClass: this.getPriorityClass(job.Priority__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load assigned jobs: ' + error.body.message, 'error');
        }
    }

    @wire(getDispatchJobs)
    wiredDispatchJobs({ error, data }) {
        if (data) {
            this.dispatchJobs = data.map(dispatch => ({
                ...dispatch,
                caseUrl: `/lightning/r/Service_Case__c/${dispatch.Service_Case__c}/view`,
                serviceDateFormatted: this.formatDateTime(dispatch.Service_Date__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load dispatch jobs: ' + error.body.message, 'error');
        }
    }

    async refreshJobs() {
        this.isLoading = true;
        try {
            await Promise.all([this.refreshAssignedJobs(), this.refreshDispatchJobs()]);
            this.showToast('Success', 'Jobs refreshed successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh jobs: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async refreshAssignedJobs() {
        try {
            const jobs = await getAssignedJobs();
            this.assignedJobs = jobs.map(job => ({
                ...job,
                caseUrl: `/lightning/r/Service_Case__c/${job.Id}/view`,
                slaDeadlineFormatted: this.formatDateTime(job.SLA_Deadline__c),
                timeRemaining: this.calculateTimeRemaining(job.SLA_Deadline__c),
                priorityClass: this.getPriorityClass(job.Priority__c)
            }));
        } catch (error) {
            console.error('Error refreshing assigned jobs:', error);
        }
    }

    async refreshDispatchJobs() {
        try {
            const dispatches = await getDispatchJobs();
            this.dispatchJobs = dispatches.map(dispatch => ({
                ...dispatch,
                caseUrl: `/lightning/r/Service_Case__c/${dispatch.Service_Case__c}/view`,
                serviceDateFormatted: this.formatDateTime(dispatch.Service_Date__c)
            }));
        } catch (error) {
            console.error('Error refreshing dispatch jobs:', error);
        }
    }

    // Handle status update button click
    handleStatusChange(caseId, newStatus, comments) {
        updateJobStatus({ caseId, newStatus, comments })
        .then(result => {
            this.showToast('Success', result, 'success');
            return refreshApex(this.assignedJobs); // Refresh dashboard data
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

        // Determine next status from workflow
    getNextStatus(currentStatus) {
        switch (currentStatus) {
            case 'Engineer Dispatched': return 'In Progress';
            case 'In Progress': return 'Resolved';
            default: return null;
        }
    }

    // Confirm update
    async confirmUpdateStatus() {
        try {
            await updateJobStatus({ caseId: this.selectedJobId, newStatus: this.nextStatus, comments: this.feedback });
            this.showToast('Success', 'Case status updated to ' + this.nextStatus, 'success');
            this.showModal = false;
            this.refreshJobs();
        } catch (error) {
            this.showToast('Error', 'Failed to update status: ' + error.body.message, 'error');
        }
    }

    closeModal() {
        this.showModal = false;
    }

    formatDateTime(dateTimeString) {
        if (!dateTimeString) return 'N/A';
        return new Date(dateTimeString).toLocaleString();
    }

    calculateTimeRemaining(slaDeadline) {
        if (!slaDeadline) return 'N/A';
        const now = new Date();
        const deadline = new Date(slaDeadline);
        const diffMs = deadline.getTime() - now.getTime();
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffDays = Math.floor(diffHours / 24);

        if (diffMs < 0) {
            return `Overdue by ${Math.abs(diffDays)} days`;
        } else if (diffDays > 0) {
            return `${diffDays} days, ${diffHours % 24} hours`;
        } else {
            return `${diffHours} hours`;
        }
    }

    getPriorityClass(priority) {
        switch (priority) {
            case 'High': return 'slds-badge slds-badge_destructive';
            case 'Medium': return 'slds-badge slds-badge_warning';
            case 'Low': return 'slds-badge slds-badge_success';
            default: return 'slds-badge';
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
