<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useAdminStore } from '../../stores/adminStore'
import type { CreateMedicPayload, Medic, UpdateMedicPayload } from '../../types'

const store = useAdminStore()
const medics = store.medics

const searchTerm = ref('')
const includeInactive = ref(false)
const isLoading = ref(false)
const loadError = ref<string | null>(null)
const showCreateForm = ref(false)
const creationError = ref<string | null>(null)
const savingNewMedic = ref(false)
const editingMedicId = ref<number | null>(null)
const editError = ref<string | null>(null)
const savingEdit = ref(false)
const actionInProgressId = ref<number | null>(null)

const newMedic = reactive({
  primerNombre: '',
  segundoNombre: '',
  apellidoPaterno: '',
  apellidoMaterno: '',
  cedula: '',
  especialidad: '',
  email: '',
  telefono: ''
})

const editForm = reactive({
  primerNombre: '',
  segundoNombre: '',
  apellidoPaterno: '',
  apellidoMaterno: '',
  cedula: '',
  especialidad: '',
  email: '',
  telefono: '',
  activo: true
})

const hasMedics = computed(() => medics.value.length > 0)

function sanitizeOptional(value: string) {
  const trimmed = value.trim()
  return trimmed.length > 0 ? trimmed : null
}

async function fetchMedics() {
  isLoading.value = true
  loadError.value = null

  try {
    await store.loadMedics(searchTerm.value, includeInactive.value)
  } catch (error) {
    loadError.value =
      error instanceof Error ? error.message : 'No fue posible obtener el listado de médicos.'
  } finally {
    isLoading.value = false
  }
}

function resetNewMedicForm() {
  newMedic.primerNombre = ''
  newMedic.segundoNombre = ''
  newMedic.apellidoPaterno = ''
  newMedic.apellidoMaterno = ''
  newMedic.cedula = ''
  newMedic.especialidad = ''
  newMedic.email = ''
  newMedic.telefono = ''
  creationError.value = null
}

function startEdit(medic: Medic) {
  editingMedicId.value = medic.id
  editForm.primerNombre = medic.primerNombre
  editForm.segundoNombre = medic.segundoNombre ?? ''
  editForm.apellidoPaterno = medic.apellidoPaterno
  editForm.apellidoMaterno = medic.apellidoMaterno ?? ''
  editForm.cedula = medic.cedula
  editForm.especialidad = medic.especialidad
  editForm.email = medic.email
  editForm.telefono = medic.telefono ?? ''
  editForm.activo = medic.activo
  editError.value = null
}

function cancelEdit() {
  editingMedicId.value = null
  editError.value = null
}

async function handleCreateMedic() {
  if (savingNewMedic.value) return

  creationError.value = null
  savingNewMedic.value = true

  const payload: CreateMedicPayload = {
    primerNombre: newMedic.primerNombre.trim(),
    segundoNombre: sanitizeOptional(newMedic.segundoNombre),
    apellidoPaterno: newMedic.apellidoPaterno.trim(),
    apellidoMaterno: sanitizeOptional(newMedic.apellidoMaterno),
    cedula: newMedic.cedula.trim(),
    especialidad: newMedic.especialidad.trim(),
    email: newMedic.email.trim(),
    telefono: sanitizeOptional(newMedic.telefono)
  }

  try {
    await store.createMedic(payload)
    resetNewMedicForm()
    showCreateForm.value = false
  } catch (error) {
    creationError.value =
      error instanceof Error ? error.message : 'No fue posible registrar al médico.'
  } finally {
    savingNewMedic.value = false
  }
}

async function handleUpdateMedic() {
  if (savingEdit.value || editingMedicId.value === null) return

  editError.value = null
  savingEdit.value = true

  const payload: UpdateMedicPayload = {
    primerNombre: editForm.primerNombre.trim(),
    segundoNombre: sanitizeOptional(editForm.segundoNombre),
    apellidoPaterno: editForm.apellidoPaterno.trim(),
    apellidoMaterno: sanitizeOptional(editForm.apellidoMaterno),
    cedula: editForm.cedula.trim(),
    especialidad: editForm.especialidad.trim(),
    email: editForm.email.trim(),
    telefono: sanitizeOptional(editForm.telefono),
    activo: editForm.activo
  }

  try {
    await store.updateMedic(editingMedicId.value, payload)
    editingMedicId.value = null
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible actualizar al médico.'
  } finally {
    savingEdit.value = false
  }
}

async function handleDeactivateMedic(medic: Medic) {
  if (actionInProgressId.value || !medic.activo) return

  const confirmDeactivate = window.confirm(
    `¿Deseas desactivar al Dr(a). ${medic.nombreCompleto}?`
  )

  if (!confirmDeactivate) {
    return
  }

  actionInProgressId.value = medic.id

  try {
    await store.deactivateMedic(medic.id)
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible desactivar al médico.'
  } finally {
    actionInProgressId.value = null
  }
}

async function handleReactivateMedic(medic: Medic) {
  if (actionInProgressId.value || medic.activo) return

  actionInProgressId.value = medic.id

  const payload: UpdateMedicPayload = {
    primerNombre: medic.primerNombre,
    segundoNombre: medic.segundoNombre ?? null,
    apellidoPaterno: medic.apellidoPaterno,
    apellidoMaterno: medic.apellidoMaterno ?? null,
    cedula: medic.cedula,
    especialidad: medic.especialidad,
    email: medic.email,
    telefono: medic.telefono ?? null,
    activo: true
  }

  try {
    await store.updateMedic(medic.id, payload)
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible reactivar al médico.'
  } finally {
    actionInProgressId.value = null
  }
}

function submitSearch() {
  void fetchMedics()
}

watch(includeInactive, () => {
  void fetchMedics()
})

onMounted(() => {
  void fetchMedics()
})
</script>

<template>
  <section class="space-y-6">
    <header class="space-y-2">
      <h2 class="text-2xl font-semibold text-white">Administrar médicos</h2>
      <p class="max-w-3xl text-sm text-slate-300/80">
        Gestiona el catálogo de médicos activos en la clínica. Podrás dar de alta nuevos especialistas, editar su
        información y controlar si se encuentran disponibles para asignarlos a usuarios y consultas.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
      <form class="flex flex-col gap-3 md:flex-row md:items-end" @submit.prevent="submitSearch">
        <div class="flex-1 space-y-2">
          <label class="text-xs font-semibold uppercase tracking-wide text-slate-400" for="search-medics"
            >Buscar</label
          >
          <input
            id="search-medics"
            v-model="searchTerm"
            class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
            placeholder="Nombre, cédula o correo"
            type="search"
          />
        </div>
        <label class="flex items-center gap-2 rounded-2xl border border-slate-800/60 bg-slate-950/50 px-4 py-3 text-xs text-slate-300">
          <input
            v-model="includeInactive"
            class="h-4 w-4 rounded border-slate-700 bg-slate-900 text-sky-500 focus:ring-sky-500"
            type="checkbox"
          />
          Incluir inactivos
        </label>
        <button
          class="rounded-2xl border border-sky-500/60 px-4 py-3 text-sm font-medium text-sky-300 transition hover:bg-sky-500/10"
          type="submit"
        >
          Buscar
        </button>
        <button
          class="rounded-2xl border border-emerald-500/60 px-4 py-3 text-sm font-medium text-emerald-300 transition hover:bg-emerald-500/10"
          type="button"
          @click="showCreateForm = !showCreateForm"
        >
          {{ showCreateForm ? 'Cerrar formulario' : 'Registrar médico' }}
        </button>
      </form>

      <transition name="fade">
        <div
          v-if="showCreateForm"
          class="mt-6 space-y-4 rounded-3xl border border-slate-800/60 bg-slate-950/60 p-6 text-sm text-slate-200"
        >
          <h3 class="text-base font-semibold text-white">Nuevo médico</h3>
          <div class="grid gap-4 md:grid-cols-2">
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-primer-nombre">Primer nombre</label>
              <input
                id="nuevo-primer-nombre"
                v-model="newMedic.primerNombre"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-segundo-nombre">Segundo nombre</label>
              <input
                id="nuevo-segundo-nombre"
                v-model="newMedic.segundoNombre"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-apellido-paterno">Apellido paterno</label>
              <input
                id="nuevo-apellido-paterno"
                v-model="newMedic.apellidoPaterno"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-apellido-materno">Apellido materno</label>
              <input
                id="nuevo-apellido-materno"
                v-model="newMedic.apellidoMaterno"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-cedula">Cédula profesional</label>
              <input
                id="nuevo-cedula"
                v-model="newMedic.cedula"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-especialidad">Especialidad</label>
              <input
                id="nuevo-especialidad"
                v-model="newMedic.especialidad"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-email">Correo electrónico</label>
              <input
                id="nuevo-email"
                v-model="newMedic.email"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="email"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-telefono">Teléfono</label>
              <input
                id="nuevo-telefono"
                v-model="newMedic.telefono"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="tel"
              />
            </div>
          </div>
          <p v-if="creationError" class="rounded-2xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-xs text-rose-200">
            {{ creationError }}
          </p>
          <div class="flex flex-col gap-3 pt-2 text-sm font-medium sm:flex-row">
            <button
              class="rounded-2xl border border-emerald-500/60 px-4 py-3 text-emerald-300 transition hover:bg-emerald-500/10 disabled:opacity-60"
              :disabled="savingNewMedic"
              type="button"
              @click="handleCreateMedic"
            >
              {{ savingNewMedic ? 'Guardando...' : 'Guardar médico' }}
            </button>
            <button
              class="rounded-2xl border border-slate-700 px-4 py-3 text-slate-300 transition hover:border-slate-500 hover:text-white"
              type="button"
              @click="showCreateForm = false"
            >
              Cancelar
            </button>
          </div>
        </div>
      </transition>

      <div class="mt-8 space-y-4">
        <p v-if="loadError" class="rounded-3xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-sm text-rose-200">
          {{ loadError }}
        </p>
        <p v-else-if="isLoading" class="text-sm text-slate-400">Cargando médicos...</p>
        <p v-else-if="!hasMedics" class="rounded-3xl border border-slate-800/60 bg-slate-950/60 px-4 py-6 text-sm text-slate-300">
          No se encontraron médicos con los criterios proporcionados.
        </p>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-800 text-left text-sm text-slate-200">
            <thead>
              <tr class="text-xs uppercase tracking-wide text-slate-400">
                <th class="px-4 py-3">Nombre</th>
                <th class="px-4 py-3">Especialidad</th>
                <th class="px-4 py-3">Cédula</th>
                <th class="px-4 py-3">Contacto</th>
                <th class="px-4 py-3">Estado</th>
                <th class="px-4 py-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-800/60">
              <tr v-for="medic in medics" :key="medic.id" class="hover:bg-slate-900/40">
                <td class="px-4 py-3">
                  <p class="font-semibold text-white">{{ medic.nombreCompleto }}</p>
                  <p class="text-xs text-slate-400">{{ medic.email }}</p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-slate-200">{{ medic.especialidad }}</p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-slate-200">{{ medic.cedula }}</p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-slate-200">{{ medic.telefono || 'Sin teléfono' }}</p>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold"
                    :class="medic.activo ? 'bg-emerald-500/10 text-emerald-300' : 'bg-slate-700/40 text-slate-300'"
                  >
                    {{ medic.activo ? 'Activo' : 'Inactivo' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-right">
                  <div class="flex flex-wrap items-center justify-end gap-2 text-xs font-medium">
                    <button
                      class="rounded-2xl border border-slate-700 px-3 py-2 text-slate-200 transition hover:border-sky-500/60 hover:text-sky-300"
                      type="button"
                      @click="startEdit(medic)"
                    >
                      Editar
                    </button>
                    <button
                      v-if="medic.activo"
                      class="rounded-2xl border border-rose-500/40 px-3 py-2 text-rose-300 transition hover:bg-rose-500/10 disabled:opacity-60"
                      :disabled="actionInProgressId === medic.id"
                      type="button"
                      @click="handleDeactivateMedic(medic)"
                    >
                      {{ actionInProgressId === medic.id ? 'Procesando...' : 'Desactivar' }}
                    </button>
                    <button
                      v-else
                      class="rounded-2xl border border-emerald-500/60 px-3 py-2 text-emerald-300 transition hover:bg-emerald-500/10 disabled:opacity-60"
                      :disabled="actionInProgressId === medic.id"
                      type="button"
                      @click="handleReactivateMedic(medic)"
                    >
                      {{ actionInProgressId === medic.id ? 'Procesando...' : 'Reactivar' }}
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <transition name="fade">
      <div
        v-if="editingMedicId !== null"
        class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6 text-sm text-slate-200"
      >
        <header class="flex items-start justify-between gap-4">
          <div>
            <h3 class="text-lg font-semibold text-white">Editar médico</h3>
            <p class="text-xs text-slate-400">Actualiza los datos antes de guardar los cambios.</p>
          </div>
          <button class="text-xs text-slate-400 hover:text-white" type="button" @click="cancelEdit">Cerrar</button>
        </header>

        <div class="mt-4 grid gap-4 md:grid-cols-2">
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-primer-nombre">Primer nombre</label>
            <input
              id="editar-primer-nombre"
              v-model="editForm.primerNombre"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-segundo-nombre">Segundo nombre</label>
            <input
              id="editar-segundo-nombre"
              v-model="editForm.segundoNombre"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-apellido-paterno">Apellido paterno</label>
            <input
              id="editar-apellido-paterno"
              v-model="editForm.apellidoPaterno"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-apellido-materno">Apellido materno</label>
            <input
              id="editar-apellido-materno"
              v-model="editForm.apellidoMaterno"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-cedula">Cédula profesional</label>
            <input
              id="editar-cedula"
              v-model="editForm.cedula"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-especialidad">Especialidad</label>
            <input
              id="editar-especialidad"
              v-model="editForm.especialidad"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-email">Correo electrónico</label>
            <input
              id="editar-email"
              v-model="editForm.email"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="email"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-telefono">Teléfono</label>
            <input
              id="editar-telefono"
              v-model="editForm.telefono"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="tel"
            />
          </div>
          <label class="flex items-center gap-2 rounded-2xl border border-slate-800/60 bg-slate-950/60 px-4 py-3 text-xs text-slate-300">
            <input
              v-model="editForm.activo"
              class="h-4 w-4 rounded border-slate-700 bg-slate-900 text-emerald-500 focus:ring-emerald-500"
              type="checkbox"
            />
            Médico activo
          </label>
        </div>

        <p v-if="editError" class="mt-4 rounded-2xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-xs text-rose-200">
          {{ editError }}
        </p>

        <div class="mt-6 flex flex-col gap-3 text-sm font-medium sm:flex-row">
          <button
            class="rounded-2xl border border-sky-500/60 px-4 py-3 text-sky-300 transition hover:bg-sky-500/10 disabled:opacity-60"
            :disabled="savingEdit"
            type="button"
            @click="handleUpdateMedic"
          >
            {{ savingEdit ? 'Guardando...' : 'Guardar cambios' }}
          </button>
          <button
            class="rounded-2xl border border-slate-700 px-4 py-3 text-slate-300 transition hover:border-slate-500 hover:text-white"
            type="button"
            @click="cancelEdit"
          >
            Cancelar
          </button>
        </div>
      </div>
    </transition>
  </section>
</template>
