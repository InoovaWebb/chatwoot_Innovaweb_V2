import { frontendURL } from '../../../helper/URLHelper';
const LeadsDashboardPage = () => import('./LeadsDashboardPage.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/leads-dashboard'),
      name: 'leads_dashboard_index',
      roles: ['administrator', 'agent'],
      component: LeadsDashboardPage,
    },
  ],
};
