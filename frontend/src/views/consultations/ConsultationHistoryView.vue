<script setup lang="ts">
import { computed, ref } from 'vue'
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

const filteredConsultations = computed(() => {
  const start = new Date(startDate.value)
  start.setHours(0, 0, 0, 0)
  const end = new Date(endDate.value)
  end.setHours(23, 59, 59, 999)

  return store.consultations.value.filter((consulta) => {
    const date = new Date(consulta.fecha)
    return date >= start && date <= end
  })
})

const patientsById = computed(() => {
  const map = new Map(store.patients.value.map((patient) => [patient.id, patient]))
  return map
})
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
              v-for="consulta in filteredConsultations"
              :key="consulta.id"
              class="border-b border-slate-800/60 text-slate-200 transition hover:bg-slate-800/40"
            >
              <td class="px-6 py-4">
                <p class="font-semibold text-white">
                  {{ patientsById.get(consulta.pacienteId)?.nombreCompleto ?? 'Paciente no registrado' }}
                </p>
                <p class="text-xs text-slate-400">
                  {{ patientsById.get(consulta.pacienteId)?.identificador ?? 'N/A' }}
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
      <p v-if="filteredConsultations.length === 0" class="p-6 text-center text-sm text-slate-400">
        No se registran consultas en el rango seleccionado.
      </p>
    </div>
  </section>
</template>
