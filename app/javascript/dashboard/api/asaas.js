import ApiClient from './ApiClient';

class AsaasAPI extends ApiClient {
  constructor() {
    super('asaas', { accountScoped: true });
  }

  getSettings() {
    return this.axios.get(this.url);
  }

  updateSettings(data) {
    return this.axios.patch(this.url, data);
  }

  createCharge(data) {
    return this.axios.post(`${this.url}/create_charge`, data);
  }
}

export default new AsaasAPI();
