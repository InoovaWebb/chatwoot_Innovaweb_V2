<script setup>
import { ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AsaasChargeModal from './AsaasChargeModal.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const isModalOpen = ref(false);

const openModal = () => {
  isModalOpen.value = true;
};

const closeModal = () => {
  isModalOpen.value = false;
};
</script>

<template>
  <div class="px-4 py-2">
    <Button
      variant="outline"
      color="slate"
      class="w-full justify-center"
      @click="openModal"
    >
      <template #icon>
        <Icon icon="i-lucide-banknote" />
      </template>
      Nova Cobrança
    </Button>

    <AsaasChargeModal
      v-if="isModalOpen"
      :show="isModalOpen"
      :conversation-id="conversationId"
      :contact-id="contactId"
      @close="closeModal"
    />
  </div>
</template>
