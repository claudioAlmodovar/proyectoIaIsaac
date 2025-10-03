<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useClinicStore } from '../../stores/clinicStore'

const store = useClinicStore()

function formatDate(date: string) {
  return new Date(date).toLocaleString('es-MX', {
    dateStyle: 'medium',
    timeStyle: 'short'
  })
}

function defaultStartDate() {
  const date = new Date()
  date.setDate(date.getDate() - 30)
  return date.toISOString().slice(0, 10)
}

const startDate = ref(defaultStartDate())
const endDate = ref(new Date().toISOString().slice(0, 10))
const isLoading = ref(false)
const loadError = ref<string | null>(null)

const records = computed(() => store.consultationHistory.value)

async function loadHistory() {
  if (!startDate.value || !endDate.value) {
    return
  }

  const start = new Date(startDate.value)
  const end = new Date(endDate.value)

  if (start > end) {
    loadError.value = 'La fecha inicial no puede ser posterior a la fecha final.'
    isLoading.value = false
    return
  }

  isLoading.value = true
  loadError.value = null

  try {
    await store.loadConsultationHistory(startDate.value, endDate.value)
  } catch (error) {
    loadError.value =
      error instanceof Error ? error.message : 'No fue posible obtener el historial de consultas.'
  } finally {
    isLoading.value = false
  }
}

watch([startDate, endDate], () => {
  void loadHistory()
}, { immediate: true })
</script>

<template>
  <section class="space-y-8">
    <header class="space-y-3">
      <h2 class="text-2xl font-semibold text-white">Historial de consultas</h2>
      <p class="max-w-3xl text-sm text-slate-300/80">
        Revisa todas las consultas registradas en el sistema, ordenadas de la más reciente a la más antigua. Puedes ajustar el
        rango de fechas según lo requieras.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
      <h3 class="text-sm font-semibold uppercase tracking-[0.35em] text-slate-400/70">Filtrar por fechas</h3>
      <div class="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <label class="space-y-2 text-xs font-medium text-slate-300" for="fecha-inicial">
          Fecha inicial
          <input
            id="fecha-inicial"
            v-model="startDate"
            class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/40"
            type="date"
          />
        </label>
        <label class="space-y-2 text-xs font-medium text-slate-300" for="fecha-final">
          Fecha final
          <input
            id="fecha-final"
            v-model="endDate"
            class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/40"
            type="date"
          />
        </label>
      </div>
    </div>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60">
      <div v-if="loadError" class="p-6 text-center text-sm text-rose-200">
        {{ loadError }}
      </div>
      <div
        v-else-if="isLoading"
        class="p-6 text-center text-sm text-slate-300/80"
      >
        Cargando historial de consultas…
      </div>
      <div v-else>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-800 text-sm">
            <thead class="bg-slate-900/60 text-xs uppercase tracking-[0.35em] text-slate-400/70">
              <tr>
                <th class="px-6 py-4 text-left">Paciente</th>
                <th class="px-6 py-4 text-left">Fecha</th>
                <th class="px-6 py-4 text-left">Notas</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="consulta in records"
                :key="consulta.id"
                class="border-b border-slate-800/60 text-slate-200 transition hover:bg-slate-800/40"
              >
                <td class="px-6 py-4">
                  <p class="font-semibold text-white">
                    {{ consulta.paciente.nombreCompleto }}
                  </p>
                  <p class="text-xs text-slate-400">
                    {{ consulta.paciente.identificador }}
                  </p>
                </td>
                <td class="px-6 py-4 text-xs text-slate-300">{{ formatDate(consulta.fecha) }}</td>
                <td class="px-6 py-4 text-xs text-slate-300/80">
                  <p class="max-h-32 overflow-y-auto whitespace-pre-line">{{ consulta.notas }}</p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <p v-if="records.length === 0" class="p-6 text-center text-sm text-slate-400">
          No se registran consultas en el rango seleccionado.
        </p>
      </div>
    </div>
  </section>
</template>
