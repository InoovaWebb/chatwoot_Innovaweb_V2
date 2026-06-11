<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import asaasApi from 'dashboard/api/asaas';

import Modal from 'dashboard/components/Modal.vue';
import ModalHeader from 'dashboard/components/ModalHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  show: { type: Boolean, default: false },
  conversationId: { type: [Number, String], required: true },
  contactId: { type: [Number, String], required: true },
});

const emit = defineEmits(['close']);

const store = useStore();
const contactGetter = useMapGetter('contacts/getContact');
const contact = computed(() => contactGetter.value(props.contactId));

const isLoading = ref(false);

const charge = ref({
  name: '',
  email: '',
  cpfCnpj: '',
  value: '',
  dueDate: '',
  billingType: 'BOLETO',
  description: '',
  subscription: false,
  fine: '',
  interest: '',
  discount: '',
  sendAsaasNotification: false,
});

onMounted(() => {
  if (contact.value) {
    charge.value.name = contact.value.name || '';
    charge.value.email = contact.value.email || '';
    charge.value.cpfCnpj = contact.value.custom_attributes?.cpf || '';
  }
  
  // Vencimento padrão para amanhã
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  charge.value.dueDate = tomorrow.toISOString().split('T')[0];
});

const onClose = () => {
  emit('close');
};

const validateCharge = () => {
  if (!charge.value.name || !charge.value.cpfCnpj || !charge.value.value || !charge.value.dueDate) {
    useAlert('Preencha os campos obrigatórios (Nome, CPF/CNPJ, Valor, Vencimento)');
    return false;
  }
  return true;
};

const generateCharge = async () => {
  if (!validateCharge()) return;
  
  isLoading.value = true;
  try {
    await asaasApi.createCharge({
      conversation_id: props.conversationId,
      contact_id: props.contactId,
      charge: charge.value
    });
    useAlert('Cobrança gerada com sucesso! Um link foi enviado no chat.');
    onClose();
  } catch (error) {
    useAlert(error?.response?.data?.error || 'Erro ao gerar cobrança no Asaas.');
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <Modal :show="show" :on-close="onClose" class="asaas-modal">
    <ModalHeader
      header-title="Nova Cobrança Asaas"
      header-content="Gere boletos, Pix ou assinaturas diretamente para este contato."
      icon="i-lucide-banknote"
    />
    
    <div class="px-8 py-4 overflow-y-auto max-h-[70vh]">
      <!-- Dados do Cliente -->
      <div class="mb-6">
        <h3 class="text-sm font-semibold text-n-slate-12 mb-3 pb-2 border-b border-n-weak">
          Dados do Cliente
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Nome Completo *
            <input v-model="charge.name" type="text" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            CPF / CNPJ *
            <input v-model="charge.cpfCnpj" type="text" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11 md:col-span-2">
            E-mail
            <input v-model="charge.email" type="email" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
        </div>
      </div>

      <!-- Dados da Cobrança -->
      <div class="mb-6">
        <h3 class="text-sm font-semibold text-n-slate-12 mb-3 pb-2 border-b border-n-weak">
          Dados da Cobrança
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Valor (R$) *
            <input v-model="charge.value" type="number" step="0.01" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Vencimento *
            <input v-model="charge.dueDate" type="date" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Método
            <select v-model="charge.billingType" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background">
              <option value="BOLETO">Boleto / Pix</option>
              <option value="PIX">Apenas Pix</option>
              <option value="CREDIT_CARD">Cartão de Crédito</option>
            </select>
          </label>
        </div>

        <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11 mb-4">
          Descrição (Impressa no boleto)
          <textarea v-model="charge.description" rows="2" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background"></textarea>
        </label>
      </div>

      <!-- Configurações Avançadas -->
      <div class="mb-2">
        <h3 class="text-sm font-semibold text-n-slate-12 mb-3 pb-2 border-b border-n-weak">
          Configurações Avançadas (Opcional)
        </h3>
        
        <div class="flex items-center gap-6 mb-4">
          <label class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer">
            <input v-model="charge.subscription" type="checkbox" class="w-4 h-4 text-n-brand rounded border-n-weak focus:ring-n-brand" />
            É uma Assinatura Mensal?
          </label>
          <label class="flex items-center gap-2 text-sm text-n-slate-12 cursor-pointer">
            <input v-model="charge.sendAsaasNotification" type="checkbox" class="w-4 h-4 text-n-brand rounded border-n-weak focus:ring-n-brand" />
            Ativar notificações do Asaas
          </label>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Multa (%)
            <input v-model="charge.fine" type="number" step="0.01" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Juros ao mês (%)
            <input v-model="charge.interest" type="number" step="0.01" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
          <label class="flex flex-col gap-1 text-sm font-medium text-n-slate-11">
            Desconto (R$)
            <input v-model="charge.discount" type="number" step="0.01" class="px-3 py-2 border border-n-weak rounded-md text-n-slate-12 bg-n-background" />
          </label>
        </div>
      </div>
    </div>

    <div class="flex justify-end gap-3 px-8 py-4 border-t border-n-weak bg-n-solid-1">
      <Button variant="ghost" color="slate" @click="onClose">
        Cancelar
      </Button>
      <Button :is-loading="isLoading" @click="generateCharge">
        <template #icon><Icon icon="i-lucide-check-circle" /></template>
        Gerar Cobrança
      </Button>
    </div>
  </Modal>
</template>

<style scoped>
.asaas-modal {
  /* Customize se precisar aumentar a largura no Vue 3 Chatwoot */
  --modal-max-width: 600px;
}
</style>
