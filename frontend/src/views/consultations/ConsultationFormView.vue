<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useClinicStore } from '../../stores/clinicStore'
import type { Consultation } from '../../types'

const props = defineProps<{ patientId: string }>()

const router = useRouter()
const store = useClinicStore()

const notas = ref('')
const showReport = ref(false)
const createdConsultation = ref<Consultation | null>(null)

const patientIdNumber = computed(() => Number(props.patientId))
const patient = computed(() => store.findPatientById(patientIdNumber.value))
const previousConsultations = computed(() =>
  patient.value ? store.findConsultationsByPatient(patient.value.id).slice(0, 5) : []
)

onMounted(() => {
  if (!patient.value) {
    router.replace({ name: 'consultas-buscar' })
  }
})

function formatDate(date: string) {
  return new Date(date).toLocaleString('es-MX', {
    dateStyle: 'medium',
    timeStyle: 'short'
  })
}

function handleSubmit() {
  if (!patient.value || !notas.value.trim()) return

  const nuevaConsulta = store.addConsultation({
    pacienteId: patient.value.id,
    notas: notas.value.trim()
  })

  createdConsultation.value = nuevaConsulta
  showReport.value = true
  notas.value = ''
}

function closeReport() {
  showReport.value = false
  createdConsultation.value = null
  router.push({ name: 'consultas-buscar' })
}
</script>

<template>
  <section v-if="patient" class="space-y-8">
    <header class="space-y-3">
      <h2 class="text-2xl font-semibold text-white">Nueva consulta</h2>
      <p class="max-w-3xl text-sm text-slate-300/80">
        Registra los hallazgos clínicos para {{ patient.nombreCompleto }}. Antes de guardar, revisa las últimas consultas
        registradas en el historial.
      </p>
    </header>

    <div class="grid gap-6 lg:grid-cols-[2fr,1fr]">
      <div class="space-y-6">
        <article class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
          <h3 class="text-lg font-semibold text-white">Datos del paciente</h3>
          <dl class="mt-4 grid gap-3 text-sm text-slate-300/80">
            <div class="flex justify-between">
              <dt class="text-slate-400">Nombre completo</dt>
              <dd>{{ patient.nombreCompleto }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-slate-400">Identificador</dt>
              <dd>{{ patient.identificador }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-slate-400">Fecha de nacimiento</dt>
              <dd>{{ patient.fechaNacimiento }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-slate-400">Sexo</dt>
              <dd>{{ patient.sexo === 'F' ? 'Femenino' : 'Masculino' }}</dd>
            </div>
          </dl>
        </article>

        <form class="space-y-4" @submit.prevent="handleSubmit">
          <label class="text-sm font-medium text-slate-200" for="notas">Notas de la consulta</label>
          <textarea
            id="notas"
            v-model="notas"
            class="h-64 w-full rounded-3xl border border-slate-800 bg-slate-950/70 px-4 py-4 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/40"
            placeholder="Describe los hallazgos, recomendaciones y tratamiento sugerido..."
          ></textarea>
          <div class="flex justify-end">
            <button
              class="inline-flex items-center gap-2 rounded-2xl bg-sky-500 px-6 py-3 text-sm font-semibold text-slate-950 transition hover:bg-sky-400 disabled:cursor-not-allowed disabled:bg-sky-500/50"
              :disabled="!notas.trim()"
              type="submit"
            >
              Guardar consulta
            </button>
          </div>
        </form>
      </div>

      <aside class="space-y-4">
        <h3 class="text-sm font-semibold uppercase tracking-[0.35em] text-slate-400/70">Últimas consultas</h3>
        <ul class="space-y-4">
          <li
            v-for="consulta in previousConsultations"
            :key="consulta.id"
            class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-4"
          >
            <p class="text-xs font-semibold text-slate-300">{{ formatDate(consulta.fecha) }}</p>
            <p class="mt-2 max-h-32 overflow-y-auto whitespace-pre-line text-xs text-slate-300/80">{{ consulta.notas }}</p>
          </li>
        </ul>
        <p v-if="previousConsultations.length === 0" class="rounded-3xl border border-dashed border-slate-800/60 bg-slate-900/40 p-4 text-xs text-slate-400">
          No hay consultas registradas previamente para este paciente.
        </p>
      </aside>
    </div>

    <transition name="fade">
      <div
        v-if="showReport && createdConsultation"
        class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 p-6"
      >
        <div class="w-full max-w-2xl rounded-3xl border border-slate-700 bg-slate-900 p-8 shadow-2xl">
          <header class="mb-6 border-b border-slate-800 pb-4">
            <p class="text-xs uppercase tracking-[0.35em] text-slate-400/70">Reporte de consulta</p>
            <h3 class="mt-2 text-xl font-semibold text-white">{{ patient.nombreCompleto }}</h3>
            <p class="text-sm text-slate-300/80">{{ formatDate(createdConsultation.fecha) }}</p>
          </header>
          <section class="space-y-3 text-sm text-slate-200">
            <h4 class="font-semibold text-slate-100">Notas médicas</h4>
            <p class="whitespace-pre-line text-slate-300/80">{{ createdConsultation.notas }}</p>
          </section>
          <footer class="mt-8 flex justify-end">
            <button
              class="inline-flex items-center gap-2 rounded-2xl bg-emerald-500 px-5 py-2 text-sm font-semibold text-slate-950 transition hover:bg-emerald-400"
              type="button"
              @click="closeReport"
            >
              Cerrar y regresar a consultas
            </button>
          </footer>
        </div>
      </div>
    </transition>
  </section>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(4px);
}
</style>
