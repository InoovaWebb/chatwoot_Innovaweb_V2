<script>
import { useAlert } from 'dashboard/composables';
import asaasApi from '../../../../api/asaas';
import Button from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Button,
  },
  data() {
    return {
      isLoading: false,
      isFetching: true,
      apiKey: '',
      environment: 'sandbox',
    };
  },
  mounted() {
    this.fetchSettings();
  },
  methods: {
    async fetchSettings() {
      try {
        const response = await asaasApi.getSettings();
        this.apiKey = response.data.asaas_api_key;
        this.environment = response.data.asaas_environment || 'sandbox';
      } catch (error) {
        useAlert('Erro ao buscar configurações do Asaas');
      } finally {
        this.isFetching = false;
      }
    },
    async saveSettings() {
      this.isLoading = true;
      try {
        await asaasApi.updateSettings({
          asaas_api_key: this.apiKey,
          asaas_environment: this.environment,
        });
        useAlert('Configurações salvas com sucesso!');
      } catch (error) {
        useAlert('Erro ao salvar as configurações');
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div class="column content-box">
    <div v-if="isFetching" class="flex justify-center items-center h-full">
      <div class="w-8 h-8 border-4 border-t-4 rounded-full animate-spin border-n-brand border-t-transparent"></div>
    </div>
    
    <div v-else class="max-w-2xl">
      <div class="flex items-center gap-4 mb-6">
        <!-- Logo SVG do Asaas - cor oficial azul escuro/branco -->
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 100" class="h-8">
          <g fill="#002157">
            <path d="M53.1 71.9c-4.4 0-7.9-3.5-7.9-7.9s3.5-7.9 7.9-7.9 7.9 3.5 7.9 7.9-3.5 7.9-7.9 7.9zm0-23.7c-8.7 0-15.8 7.1-15.8 15.8S44.4 79.8 53.1 79.8s15.8-7.1 15.8-15.8S61.8 48.2 53.1 48.2zM18.4 71.9c-4.4 0-7.9-3.5-7.9-7.9s3.5-7.9 7.9-7.9 7.9 3.5 7.9 7.9-3.5 7.9-7.9 7.9zm0-23.7c-8.7 0-15.8 7.1-15.8 15.8S9.7 79.8 18.4 79.8 34.2 72.7 34.2 64 27.1 48.2 18.4 48.2zM36.1 40.5L36.1 24.3 0 24.3l0 16.2z"/>
            <path d="M125.7 78.4L117.8 78.4 115.1 69.1 98.7 69.1 96 78.4 88.1 78.4 103.4 31 110.3 31 125.7 78.4zM106.9 40L100.8 61.2 112.9 61.2 106.9 40zM148.9 79.1C138.8 79.1 131.7 73 131.7 63.8L131.7 63.2 139.1 63.2C139.1 69.1 143.4 72.4 148.9 72.4 153.8 72.4 156.9 70.1 156.9 66.4L156.9 65.8C156.9 62.6 154.5 61.3 149.3 59.9L144.1 58.5C136 56.4 131.8 52.8 131.8 46.2L131.8 45.6C131.8 37.1 139 31 148.4 31 157.9 31 164.6 36.6 164.6 45.2L164.6 45.8 157.2 45.8C157.2 40.3 153.6 37.7 148.4 37.7 143.9 37.7 141.1 39.9 141.1 43.4L141.1 43.9C141.1 47 143.6 48.5 148.8 49.9L154.1 51.3C162.2 53.4 166.4 57.1 166.4 63.5L166.4 64.1C166.4 72.6 159.2 79.1 148.9 79.1zM203.2 78.4L195.3 78.4 192.6 69.1 176.2 69.1 173.5 78.4 165.6 78.4 180.9 31 187.8 31 203.2 78.4zM184.4 40L178.3 61.2 190.4 61.2 184.4 40zM226.4 79.1C216.3 79.1 209.2 73 209.2 63.8L209.2 63.2 216.6 63.2C216.6 69.1 220.9 72.4 226.4 72.4 231.3 72.4 234.4 70.1 234.4 66.4L234.4 65.8C234.4 62.6 232 61.3 226.8 59.9L221.6 58.5C213.5 56.4 209.3 52.8 209.3 46.2L209.3 45.6C209.3 37.1 216.5 31 225.9 31 235.4 31 242.1 36.6 242.1 45.2L242.1 45.8 234.7 45.8C234.7 40.3 231.1 37.7 225.9 37.7 221.4 37.7 218.6 39.9 218.6 43.4L218.6 43.9C218.6 47 221.1 48.5 226.3 49.9L231.6 51.3C239.7 53.4 243.9 57.1 243.9 63.5L243.9 64.1C243.9 72.6 236.7 79.1 226.4 79.1z"/>
          </g>
        </svg>
        <h2 class="text-xl font-medium text-n-slate-12 mb-0">Integração Asaas</h2>
      </div>
      
      <p class="text-sm text-n-slate-11 mb-6">
        Configure as suas credenciais do Asaas para gerar boletos e Pix diretamente pelo Chatwoot.
      </p>

      <div class="bg-white dark:bg-n-solid-2 border border-n-weak rounded-md p-6">
        <form @submit.prevent="saveSettings" class="flex flex-col gap-6">
          
          <div class="flex flex-col gap-2">
            <label class="text-sm font-medium text-n-slate-12">Ambiente</label>
            <select
              v-model="environment"
              class="w-full p-2 border border-n-weak rounded-md bg-n-background text-n-slate-12 focus:ring-1 focus:ring-n-brand"
            >
              <option value="sandbox">Ambiente de Testes (Sandbox)</option>
              <option value="production">Produção (Real)</option>
            </select>
            <span class="text-xs text-n-slate-11">
              O ambiente de Testes utiliza dinheiro de mentira. Não gera cobranças reais.
            </span>
          </div>

          <div class="flex flex-col gap-2">
            <label class="text-sm font-medium text-n-slate-12">Chave de API ($ACCESS_TOKEN)</label>
            <input
              v-model="apiKey"
              type="password"
              placeholder="Ex: $aact_YTU5YTE0M2M2N2I4MTliNDQ2NDQ4OT..."
              class="w-full p-2 border border-n-weak rounded-md bg-n-background text-n-slate-12 focus:ring-1 focus:ring-n-brand"
            />
            <span class="text-xs text-n-slate-11">
              Você pode encontrar a sua Chave de API acessando o painel do Asaas em Configurações > Integrações.
            </span>
          </div>

          <div class="flex items-center justify-between mt-2 pt-4 border-t border-n-weak">
            <div class="flex items-center gap-2">
              <span v-if="apiKey && apiKey.length > 5" class="flex items-center gap-1 text-sm text-green-600 font-medium">
                <span class="w-2 h-2 rounded-full bg-green-500"></span>
                Conectado
              </span>
              <span v-else class="flex items-center gap-1 text-sm text-n-slate-11 font-medium">
                <span class="w-2 h-2 rounded-full bg-n-slate-11"></span>
                Desconectado
              </span>
            </div>
            
            <Button
              :is-loading="isLoading"
              type="submit"
            >
              Salvar Configurações
            </Button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
