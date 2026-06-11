import ApiClient from './ApiClient';

class LeadsDashboardAPI extends ApiClient {
  constructor() {
    super('leads_dashboard', { accountScoped: true });
  }

  getMetrics({ startDate, endDate, inboxId }) {
    const params = new URLSearchParams();
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);
    if (inboxId) params.append('inbox_id', inboxId);

    return this.axiosInstance.get(`${this.url}?${params.toString()}`);
  }
}

export default new LeadsDashboardAPI();
