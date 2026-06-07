<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import ContactAPI from 'dashboard/api/contacts';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['close']);

const { t } = useI18n();
const dialogRef = ref(null);

// Inboxes da conta
const inboxes = useMapGetter('inboxes/getInboxes');

// Formulário
const selectedInboxId = ref('');
const startDate = ref('');
const endDate = ref('');
const isLoading = ref(false);
const errorMsg = ref('');

// Data padrão: início e fim do mês atual
onMounted(() => {
  const now = new Date();
  const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
  const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  startDate.value = firstDay.toISOString().split('T')[0];
  endDate.value = lastDay.toISOString().split('T')[0];
});

const selectedInboxName = computed(() => {
  if (!selectedInboxId.value) return 'Todas';
  return inboxes.value.find(i => i.id === Number(selectedInboxId.value))?.name || 'Todas';
});

const isValid = computed(() => {
  if (!startDate.value || !endDate.value) return false;
  return new Date(startDate.value) <= new Date(endDate.value);
});

const downloadLeads = async () => {
  if (!isValid.value) {
    errorMsg.value = 'A data inicial deve ser menor ou igual à data final.';
    return;
  }
  errorMsg.value = '';
  isLoading.value = true;

  try {
    const response = await ContactAPI.exportLeads({
      startDate: startDate.value,
      endDate: endDate.value,
      inboxId: selectedInboxId.value || null,
    });

    // Força o download do arquivo CSV
    const blob = new Blob([response.data], { type: 'text/csv;charset=utf-8;' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    const inboxSlug = selectedInboxName.value.toLowerCase().replace(/\s+/g, '_');
    link.download = `leads_${inboxSlug}_${startDate.value}_a_${endDate.value}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

    dialogRef.value?.close();
  } catch (err) {
    errorMsg.value = 'Erro ao exportar. Tente novamente.';
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    title="📥 Exportar Leads"
    description="Selecione a caixa de entrada e o período para baixar o CSV com nome e telefone."
    confirm-button-label="⬇ Baixar CSV"
    :is-loading="isLoading"
    :disable-confirm-button="!isValid || isLoading"
    @confirm="downloadLeads"
  >
    <div class="mt-4 flex flex-col gap-4">
      <!-- Caixa de entrada -->
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          Caixa de Entrada
        </label>
        <select
          v-model="selectedInboxId"
          class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
        >
          <option value="">✅ Todas as caixas</option>
          <option
            v-for="inbox in inboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
      </div>

      <!-- Período -->
      <div class="flex gap-3">
        <div class="flex flex-col gap-1 flex-1">
          <label class="text-sm font-medium text-n-slate-12">De:</label>
          <input
            v-model="startDate"
            type="date"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          />
        </div>
        <div class="flex flex-col gap-1 flex-1">
          <label class="text-sm font-medium text-n-slate-12">Até:</label>
          <input
            v-model="endDate"
            type="date"
            class="w-full rounded-lg border border-n-weak bg-n-alpha-1 px-3 py-2 text-sm text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
          />
        </div>
      </div>

      <!-- Erro -->
      <p v-if="errorMsg" class="text-sm text-red-500">{{ errorMsg }}</p>
    </div>
  </Dialog>
</template>
