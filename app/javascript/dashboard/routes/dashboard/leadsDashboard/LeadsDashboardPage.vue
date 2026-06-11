<script>
import { mapGetters } from 'vuex';
import LeadsDashboardAPI from '../../api/leadsDashboard';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DatePicker from 'vue-datepicker-next';
import 'vue-datepicker-next/index.css';
import { startOfMonth, endOfDay } from 'date-fns';
import { Bar } from 'vue-chartjs';
import { Chart as ChartJS, Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale } from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale);

export default {
  components: {
    Button,
    Icon,
    DatePicker,
    Bar,
  },
  data() {
    return {
      isLoading: false,
      isDownloading: false,
      metrics: {
        total_leads: 0,
        leads_per_day: [],
        labels_summary: [],
        without_label_count: 0,
        period: { start_date: '', end_date: '' }
      },
      filters: {
        inboxId: 'all',
        dateRange: [startOfMonth(new Date()), endOfDay(new Date())],
      },
    };
  },
  computed: {
    ...mapGetters({
      inboxes: 'inboxes/getInboxes',
      globalConfig: 'globalConfig/get',
    }),
    chartData() {
      return {
        labels: this.metrics.leads_per_day.map(d => d.date),
        datasets: [
          {
            label: 'Leads',
            backgroundColor: '#1f93ff',
            data: this.metrics.leads_per_day.map(d => d.count),
          },
        ],
      };
    },
    chartOptions() {
      return {
        responsive: true,
        maintainAspectRatio: false,
      };
    },
  },
  mounted() {
    this.fetchMetrics();
  },
  methods: {
    async fetchMetrics() {
      this.isLoading = true;
      try {
        const payload = {
          startDate: this.filters.dateRange[0]?.toISOString(),
          endDate: this.filters.dateRange[1]?.toISOString(),
        };
        if (this.filters.inboxId !== 'all') {
          payload.inboxId = this.filters.inboxId;
        }

        const response = await LeadsDashboardAPI.getMetrics(payload);
        this.metrics = response.data;
      } catch (error) {
        useAlert('Erro ao buscar métricas');
      } finally {
        this.isLoading = false;
      }
    },
    async loadJsPDF() {
      if (window.jspdf && window.jspdf.jsPDF) return window.jspdf.jsPDF;
      return new Promise((resolve, reject) => {
        const script1 = document.createElement('script');
        script1.src = 'https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js';
        script1.onload = () => {
          const script2 = document.createElement('script');
          script2.src = 'https://cdnjs.cloudflare.com/ajax/libs/jspdf-autotable/3.8.2/jspdf.plugin.autotable.min.js';
          script2.onload = () => resolve(window.jspdf.jsPDF);
          script2.onerror = reject;
          document.head.appendChild(script2);
        };
        script1.onerror = reject;
        document.head.appendChild(script1);
      });
    },
    async downloadPDF() {
      this.isDownloading = true;
      try {
        const jsPDF = await this.loadJsPDF();
        const doc = new jsPDF();
        
        const companyName = this.globalConfig.installationName || 'SaaS';
        const dateStr = `${this.metrics.period.start_date} a ${this.metrics.period.end_date}`;
        
        let inboxName = 'Todas';
        if (this.filters.inboxId !== 'all') {
          const inbox = this.inboxes.find(i => i.id === this.filters.inboxId);
          if (inbox) inboxName = inbox.name;
        }

        doc.setFontSize(16);
        doc.text(`RELATÓRIO DE LEADS - ${companyName}`, 14, 22);
        
        doc.setFontSize(10);
        doc.text(`Período: ${dateStr}`, 14, 30);
        doc.text(`Caixa: ${inboxName}`, 14, 35);
        doc.text(`Gerado em: ${new Date().toLocaleString()}`, 14, 40);

        doc.setFontSize(12);
        doc.text('RESUMO GERAL', 14, 55);
        
        const withLabels = this.metrics.total_leads - this.metrics.without_label_count;
        const withLabelsPct = this.metrics.total_leads > 0 ? Math.round((withLabels / this.metrics.total_leads) * 100) : 0;
        const withoutLabelsPct = this.metrics.total_leads > 0 ? Math.round((this.metrics.without_label_count / this.metrics.total_leads) * 100) : 0;

        doc.autoTable({
          startY: 60,
          head: [['Métrica', 'Valor']],
          body: [
            ['Total de Leads', this.metrics.total_leads],
            ['Com Etiqueta', `${withLabels} (${withLabelsPct}%)`],
            ['Sem Etiqueta', `${this.metrics.without_label_count} (${withoutLabelsPct}%)`]
          ],
          theme: 'grid'
        });

        const finalY = doc.lastAutoTable.finalY || 60;
        
        doc.text('LEADS POR ETIQUETA', 14, finalY + 15);

        const tableData = this.metrics.labels_summary.map(l => [
          l.label,
          l.count,
          `${l.percentage}%`
        ]);

        doc.autoTable({
          startY: finalY + 20,
          head: [['Etiqueta', 'Quantidade', '% do Total']],
          body: tableData,
          theme: 'striped'
        });

        doc.setFontSize(8);
        const pageCount = doc.internal.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
          doc.setPage(i);
          doc.text(
            `Gerado em ${new Date().toLocaleString()}`,
            doc.internal.pageSize.width / 2,
            doc.internal.pageSize.height - 10,
            { align: 'center' }
          );
        }

        doc.save(`leads_${companyName.replace(/\\s+/g, '_').toLowerCase()}_${new Date().getTime()}.pdf`);
        useAlert('PDF gerado com sucesso!');
      } catch (error) {
        useAlert('Erro ao gerar PDF');
      } finally {
        this.isDownloading = false;
      }
    }
  }
};
</script>

<template>
  <div class="flex-1 w-full p-6 overflow-auto bg-n-background">
    <div class="flex flex-row justify-between items-center mb-6">
      <h1 class="text-2xl font-semibold text-n-slate-12">📊 Dashboard de Leads</h1>
      <Button
        :is-loading="isDownloading"
        @click="downloadPDF"
      >
        <template #icon>
          <Icon icon="i-lucide-file-down" />
        </template>
        📄 Baixar Relatório PDF
      </Button>
    </div>

    <!-- Filtros -->
    <div class="flex gap-4 mb-6 bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak">
      <div class="flex flex-col gap-1 w-64">
        <label class="text-xs font-medium text-n-slate-11">Caixa de Entrada</label>
        <select
          v-model="filters.inboxId"
          class="w-full px-3 py-2 text-sm border rounded-md border-n-weak bg-n-background text-n-slate-12"
          @change="fetchMetrics"
        >
          <option value="all">Todas as Caixas</option>
          <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox.id">
            {{ inbox.name }}
          </option>
        </select>
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-xs font-medium text-n-slate-11">Período</label>
        <DatePicker
          v-model="filters.dateRange"
          type="date"
          range
          format="DD/MM/YYYY"
          class="!w-64"
          @change="fetchMetrics"
        />
      </div>
    </div>

    <!-- Spinner -->
    <div v-if="isLoading" class="flex justify-center my-10">
      <div class="w-8 h-8 border-4 border-t-4 rounded-full animate-spin border-n-brand border-t-transparent"></div>
    </div>

    <div v-else>
      <!-- Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak">
          <div class="text-sm font-medium text-n-slate-11 mb-1">📥 Total de Leads</div>
          <div class="text-2xl font-bold text-n-slate-12">{{ metrics.total_leads }}</div>
        </div>
        <div class="bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak">
          <div class="text-sm font-medium text-n-slate-11 mb-1">✅ Com Etiqueta</div>
          <div class="text-2xl font-bold text-green-600">{{ metrics.total_leads - metrics.without_label_count }}</div>
        </div>
        <div class="bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak">
          <div class="text-sm font-medium text-n-slate-11 mb-1">⚪ Sem Etiqueta</div>
          <div class="text-2xl font-bold text-n-slate-10">{{ metrics.without_label_count }}</div>
        </div>
      </div>

      <!-- Gráfico e Tabela -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak h-96">
          <h3 class="text-base font-semibold text-n-slate-12 mb-4">Leads por Dia</h3>
          <Bar v-if="metrics.leads_per_day.length > 0" :data="chartData" :options="chartOptions" />
          <div v-else class="text-sm text-n-slate-11 flex h-full items-center justify-center">Nenhum dado no período</div>
        </div>

        <div class="bg-white dark:bg-n-solid-2 p-4 rounded-md shadow-sm border border-n-weak h-96 overflow-auto">
          <h3 class="text-base font-semibold text-n-slate-12 mb-4">Resumo por Etiqueta</h3>
          <table class="w-full text-sm text-left">
            <thead>
              <tr class="border-b border-n-weak text-n-slate-11">
                <th class="py-2">Etiqueta</th>
                <th class="py-2 text-right">Quantidade</th>
                <th class="py-2 text-right">%</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="label in metrics.labels_summary" :key="label.label" class="border-b border-n-weak">
                <td class="py-3 flex items-center gap-2">
                  <span class="w-3 h-3 rounded-sm" :style="{ backgroundColor: label.color }"></span>
                  <span class="font-medium text-n-slate-12">{{ label.label }}</span>
                </td>
                <td class="py-3 text-right text-n-slate-12">{{ label.count }}</td>
                <td class="py-3 text-right text-n-slate-11">{{ label.percentage }}%</td>
              </tr>
              <tr v-if="metrics.labels_summary.length === 0">
                <td colspan="3" class="py-4 text-center text-n-slate-11">Nenhuma etiqueta encontrada</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
