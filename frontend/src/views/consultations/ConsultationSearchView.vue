<script setup lang="ts">
import { computed, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useClinicStore } from '../../stores/clinicStore'

const router = useRouter()
const store = useClinicStore()

const state = reactive({
  searchTerm: '',
  showNewPatientForm: false,
  newPatient: {
    nombreCompleto: '',
    identificador: '',
    fechaNacimiento: '',
    sexo: 'F' as 'M' | 'F'
  }
})

const results = computed(() => store.searchPatients(state.searchTerm))
const hasSearch = computed(() => state.searchTerm.trim().length > 0)

const sexoOptions = [
  { value: 'F', label: 'Femenino' },
  { value: 'M', label: 'Masculino' }
]

function resetForm() {
  state.newPatient = {
    nombreCompleto: '',
    identificador: '',
    fechaNacimiento: '',
    sexo: 'F'
  }
}

function handleSelect(patientId: number) {
  router.push({ name: 'consultas-nueva', params: { patientId } })
}

function handleCreatePatient() {
  if (!state.newPatient.nombreCompleto || !state.newPatient.identificador || !state.newPatient.fechaNacimiento) {
    return
  }

  const patient = store.addPatient({
    nombreCompleto: state.newPatient.nombreCompleto,
    identificador: state.newPatient.identificador,
    fechaNacimiento: state.newPatient.fechaNacimiento,
    sexo: state.newPatient.sexo
  })

  state.showNewPatientForm = false
  resetForm()
  handleSelect(patient.id)
}

function cancelCreatePatient() {
  state.showNewPatientForm = false
  resetForm()
}

const canCreatePatient = computed(() => {
  return (
    state.newPatient.nombreCompleto.trim().length > 0 &&
    state.newPatient.identificador.trim().length > 0 &&
    state.newPatient.fechaNacimiento.trim().length > 0
  )
})

const showNoResults = computed(() => hasSearch.value && results.value.length === 0)
</script>

<template>
  <section class="space-y-8">
    <header class="space-y-3">
      <h2 class="text-2xl font-semibold text-white">Consultar pacientes</h2>
      <p class="max-w-3xl text-sm text-slate-300/80">
        Busca pacientes dados de alta para revisar su historial y registrar nuevas consultas. Si el paciente no existe en la
        base, podrás registrarlo inmediatamente.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
      <label class="text-sm font-medium text-slate-200" for="search">Buscar paciente</label>
      <div class="mt-2 flex flex-col gap-3 sm:flex-row">
        <input
          id="search"
          v-model="state.searchTerm"
          class="flex-1 rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
          placeholder="Nombre o identificador"
          type="search"
        />
        <button
          v-if="!state.showNewPatientForm"
          class="rounded-2xl border border-slate-700 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-sky-500/60 hover:text-sky-300"
          type="button"
          @click="state.showNewPatientForm = true"
        >
          Dar de alta paciente
        </button>
      </div>

      <transition name="fade">
        <div v-if="state.showNewPatientForm" class="mt-6 space-y-4 rounded-2xl border border-slate-800/60 bg-slate-950/60 p-4">
          <h3 class="text-sm font-semibold text-white">Registrar nuevo paciente</h3>
          <div class="grid gap-4 md:grid-cols-2">
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-nombre">Nombre completo</label>
              <input
                id="nuevo-nombre"
                v-model="state.newPatient.nombreCompleto"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                placeholder="Nombre y apellidos"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-identificador">Identificador clínico</label>
              <input
                id="nuevo-identificador"
                v-model="state.newPatient.identificador"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                placeholder="Ej. CLM-010"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-fecha">Fecha de nacimiento</label>
              <input
                id="nuevo-fecha"
                v-model="state.newPatient.fechaNacimiento"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="date"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-sexo">Sexo</label>
              <select
                id="nuevo-sexo"
                v-model="state.newPatient.sexo"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
              >
                <option v-for="option in sexoOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
            </div>
          </div>
          <div class="flex flex-col gap-3 pt-2 sm:flex-row">
            <button
              class="inline-flex flex-1 items-center justify-center gap-2 rounded-2xl bg-emerald-500 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-emerald-400 disabled:cursor-not-allowed disabled:bg-emerald-500/60"
              :disabled="!canCreatePatient"
              type="button"
              @click="handleCreatePatient"
            >
              Guardar y crear consulta
            </button>
            <button
              class="inline-flex flex-1 items-center justify-center gap-2 rounded-2xl border border-slate-800/60 px-4 py-3 text-sm font-semibold text-slate-300 transition hover:border-rose-400/60 hover:text-rose-200"
              type="button"
              @click="cancelCreatePatient"
            >
              Cancelar registro
            </button>
          </div>
        </div>
      </transition>
    </div>

    <div class="space-y-4">
      <h3 class="text-sm font-semibold uppercase tracking-[0.35em] text-slate-400/70">Resultados</h3>

      <div v-if="showNoResults" class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-8 text-center text-sm text-slate-300/80">
        <p>No se encontraron pacientes con el criterio proporcionado.</p>
        <p class="mt-2">Puedes darlos de alta con el botón "Dar de alta paciente".</p>
      </div>

      <ul v-else class="grid gap-4 lg:grid-cols-2">
        <li
          v-for="patient in results"
          :key="patient.id"
          class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6 transition hover:border-sky-500/60 hover:bg-slate-800/60"
        >
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm font-semibold text-white">{{ patient.nombreCompleto }}</p>
              <p class="text-xs text-slate-400">{{ patient.identificador }}</p>
            </div>
            <button
              class="rounded-full border border-sky-500/60 px-3 py-1 text-xs font-semibold text-sky-300 transition hover:bg-sky-500/20"
              type="button"
              @click="handleSelect(patient.id)"
            >
              Seleccionar
            </button>
          </div>
          <dl class="mt-4 grid gap-2 text-xs text-slate-300/80">
            <div class="flex justify-between">
              <dt class="font-medium text-slate-400">Fecha de nacimiento</dt>
              <dd>{{ patient.fechaNacimiento }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium text-slate-400">Sexo</dt>
              <dd>{{ patient.sexo === 'F' ? 'Femenino' : 'Masculino' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium text-slate-400">Fecha de alta</dt>
              <dd>{{ patient.fechaAlta }}</dd>
            </div>
          </dl>
        </li>
      </ul>
    </div>
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
  transform: translateY(-6px);
}
</style>
