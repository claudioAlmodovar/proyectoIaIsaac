<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useClinicStore } from '../../stores/clinicStore'
import type { Consultation, Patient } from '../../types'

const props = defineProps<{ patientId: string }>()

const router = useRouter()
const store = useClinicStore()

const notas = ref('')
const showReport = ref(false)
const createdConsultation = ref<Consultation | null>(null)
const patient = ref<Patient | null>(null)
const previousConsultations = ref<Consultation[]>([])
const isLoading = ref(true)
const loadError = ref<string | null>(null)
const isSaving = ref(false)
const saveError = ref<string | null>(null)

const patientIdNumber = computed(() => Number(props.patientId))

function formatDate(date: string) {
  return new Date(date).toLocaleString('es-MX', {
    dateStyle: 'medium',
    timeStyle: 'short'
  })
}

async function fetchPatientData() {
  isLoading.value = true
  loadError.value = null

  try {
    const targetPatient = await store.getPatientById(patientIdNumber.value)

    if (!targetPatient) {
      loadError.value = 'El paciente solicitado no existe o fue dado de baja.'
      patient.value = null
      previousConsultations.value = []
      return
    }

    patient.value = targetPatient
    previousConsultations.value = await store.getConsultationsByPatient(targetPatient.id, 5)
  } catch (error) {
    loadError.value =
      error instanceof Error ? error.message : 'No fue posible cargar la información del paciente.'
    patient.value = null
    previousConsultations.value = []
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  void fetchPatientData()
})

async function handleSubmit() {
  if (!patient.value || !notas.value.trim() || isSaving.value) return

  saveError.value = null
  isSaving.value = true

  try {
    const nuevaConsulta = await store.createConsultation({
      pacienteId: patient.value.id,
      notas: notas.value.trim()
    })

    createdConsultation.value = nuevaConsulta
    previousConsultations.value = [nuevaConsulta, ...previousConsultations.value].slice(0, 5)
    showReport.value = true
    notas.value = ''
  } catch (error) {
    saveError.value =
      error instanceof Error ? error.message : 'No fue posible guardar la consulta médica.'
  } finally {
    isSaving.value = false
  }
}

function closeReport() {
  showReport.value = false
  createdConsultation.value = null
  router.push({ name: 'consultas-buscar' })
}

function goBackToSearch() {
  router.push({ name: 'consultas-buscar' })
}
</script>

<template>
  <section class="space-y-8">
    <div
      v-if="isLoading"
      class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-8 text-center text-sm text-slate-300/80"
    >
      Cargando información del paciente…
    </div>

    <div
      v-else-if="loadError"
      class="space-y-4 rounded-3xl border border-rose-500/40 bg-rose-500/10 p-8 text-center text-sm text-rose-100"
    >
      <p>{{ loadError }}</p>
      <button
        class="inline-flex items-center justify-center gap-2 rounded-2xl border border-rose-300/60 px-4 py-2 text-xs font-semibold text-rose-100 transition hover:border-rose-200 hover:text-rose-50"
        type="button"
        @click="goBackToSearch"
      >
        Regresar a consultas
      </button>
    </div>

    <template v-else-if="patient">
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
              <div class="flex justify-between">
                <dt class="text-slate-400">Fecha de alta</dt>
                <dd>{{ patient.fechaAlta }}</dd>
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
            <p v-if="saveError" class="rounded-2xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-xs text-rose-200">
              {{ saveError }}
            </p>
            <div class="flex justify-end">
              <button
                class="inline-flex items-center gap-2 rounded-2xl bg-sky-500 px-6 py-3 text-sm font-semibold text-slate-950 transition hover:bg-sky-400 disabled:cursor-not-allowed disabled:bg-sky-500/50"
                :disabled="!notas.trim() || isSaving"
                type="submit"
              >
                {{ isSaving ? 'Guardando…' : 'Guardar consulta' }}
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
    </template>
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
