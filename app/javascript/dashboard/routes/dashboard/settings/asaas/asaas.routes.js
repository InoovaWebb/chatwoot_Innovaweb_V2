import { frontendURL } from '../../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';

const AsaasSettings = () => import('./AsaasSettings.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/asaas'),
      name: 'asaas_settings',
      roles: ROLES,
      component: AsaasSettings,
    },
  ],
};
