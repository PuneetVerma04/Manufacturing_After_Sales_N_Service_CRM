import { LightningElement, track, wire } from 'lwc';
import getManagerStats from '@salesforce/apex/ManagerController.getManagerStats';
import getCaseStatusDistribution from '@salesforce/apex/ManagerController.getCaseStatusDistribution';
import getTopProducts from '@salesforce/apex/ManagerController.getTopProducts';
import getEngineerPerformance from '@salesforce/apex/ManagerController.getEngineerPerformance';
import getSlaAnalysis from '@salesforce/apex/ManagerController.getSlaAnalysis';
import getRecentFeedback from '@salesforce/apex/ManagerController.getRecentFeedback';

export default class ManagerDashboard extends LightningElement {
    @track totalCases = 0;
    @track openCases = 0;
    @track slaBreached = 0;
    @track avgRating = 0;
    @track activeEngineers = 0;
    @track caseStatusData = [];
    @track topProducts = [];
    @track engineerPerformance = [];
    @track slaAnalysis = {};
    @track recentFeedback = [];
    
    @track showOverview = true;
    @track showEngineers = false;
    @track showSla = false;
    @track showFeedback = false;

    @wire(getManagerStats)
    wiredStats({ data }) {
        if (data) {
            this.totalCases = data.totalCases || 0;
            this.openCases = data.openCases || 0;
            this.slaBreached = data.slaBreached || 0;
            this.avgRating = data.avgRating || 0;
            this.activeEngineers = data.activeEngineers || 0;
        }
    }

    @wire(getCaseStatusDistribution)
    wiredCaseStatus({ data }) { if (data) this.caseStatusData = data; }
    @wire(getTopProducts)
    wiredTopProducts({ data }) { if (data) this.topProducts = data; }
    
    @wire(getEngineerPerformance)
    wiredEngineers({ data }) {
        if (data) {
            this.engineerPerformance = data.map(e => ({
                ...e,
                breachClass: this.getBreachClass(e.slaBreaches),
                ratingClass: this.getRatingClass(e.customerRating),
                statusClass: this.getStatusClass(e.status)
            }));
        }
    }

    @wire(getSlaAnalysis) wiredSla({ data }) { if (data) this.slaAnalysis = data; }
    @wire(getRecentFeedback) wiredFeedback({ data }) { if (data) this.recentFeedback = data.map(f => ({ ...f, ratingClass: this.getRatingClass(f.Rating__c) })); }

    switchTab(event) {
        event.preventDefault();
        const tab = event.target.dataset.tab;
        this.showOverview = tab === 'overview';
        this.showEngineers = tab === 'engineers';
        this.showSla = tab === 'sla';
        this.showFeedback = tab === 'feedback';
    }

    get summaryMetrics() {
        return [
            { label: 'Total Cases', value: this.totalCases, colorClass: 'slds-text-color_default' },
            { label: 'Open Cases', value: this.openCases, colorClass: this.openCases > 5 ? 'slds-text-color_warning' : 'slds-text-color_success' },
            { label: 'SLA Breached', value: this.slaBreached, colorClass: this.slaBreached > 0 ? 'slds-text-color_destructive' : 'slds-text-color_success' },
            { label: 'Avg Rating', value: this.avgRating.toFixed(1), colorClass: this.avgRating >= 4 ? 'slds-text-color_success' : 'slds-text-color_warning' },
            { label: 'Active Engineers', value: this.activeEngineers, colorClass: 'slds-text-color_default' }
        ];
    }

    getBreachClass(b) { return b === 0 ? 'slds-badge slds-badge_success' : (b <= 2 ? 'slds-badge slds-badge_warning' : 'slds-badge slds-badge_destructive'); }
    getRatingClass(r) { return r >= 4 ? 'slds-badge slds-badge_success' : (r >= 3 ? 'slds-badge slds-badge_warning' : 'slds-badge slds-badge_destructive'); }
    getStatusClass(s) { return s === 'Available' ? 'slds-badge slds-badge_success' : (s === 'Busy' ? 'slds-badge slds-badge_warning' : 'slds-badge slds-badge_inverse'); }
}