<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useAdminStore } from '../../stores/adminStore'
import type { CreateUserPayload, UpdateUserPayload, UserAccount } from '../../types'

const store = useAdminStore()
const users = store.users
const medics = store.medics

const searchTerm = ref('')
const includeInactive = ref(false)
const isLoading = ref(false)
const loadError = ref<string | null>(null)
const showCreateForm = ref(false)
const creationError = ref<string | null>(null)
const savingNewUser = ref(false)
const editingUserId = ref<number | null>(null)
const editError = ref<string | null>(null)
const savingEdit = ref(false)
const actionInProgressId = ref<number | null>(null)

const newUser = reactive({
  correo: '',
  nombreCompleto: '',
  password: '',
  medicoId: '' as '' | number,
  activo: true
})

const editForm = reactive({
  correo: '',
  nombreCompleto: '',
  password: '',
  medicoId: '' as '' | number,
  activo: true
})

const availableMedics = computed(() => medics.value.filter((medic) => medic.activo))
const hasUsers = computed(() => users.value.length > 0)

function normalizeMedicoId(value: '' | number): number | null {
  if (value === '' || value === null) {
    return null
  }
  const parsed = Number(value)
  return Number.isNaN(parsed) ? null : parsed
}

async function fetchUsers() {
  isLoading.value = true
  loadError.value = null

  try {
    await store.loadUsers(searchTerm.value, includeInactive.value)
  } catch (error) {
    loadError.value =
      error instanceof Error ? error.message : 'No fue posible obtener el listado de usuarios.'
  } finally {
    isLoading.value = false
  }
}

function resetNewUserForm() {
  newUser.correo = ''
  newUser.nombreCompleto = ''
  newUser.password = ''
  newUser.medicoId = ''
  newUser.activo = true
  creationError.value = null
}

function startEdit(user: UserAccount) {
  editingUserId.value = user.id
  editForm.correo = user.correo
  editForm.nombreCompleto = user.nombreCompleto
  editForm.password = ''
  editForm.medicoId = user.medicoId ?? ''
  editForm.activo = user.activo
  editError.value = null
}

function cancelEdit() {
  editingUserId.value = null
  editError.value = null
}

async function handleCreateUser() {
  if (savingNewUser.value) return

  creationError.value = null
  savingNewUser.value = true

  const payload: CreateUserPayload = {
    correo: newUser.correo.trim(),
    password: newUser.password,
    nombreCompleto: newUser.nombreCompleto.trim(),
    medicoId: normalizeMedicoId(newUser.medicoId),
    activo: newUser.activo
  }

  try {
    await store.createUser(payload)
    resetNewUserForm()
    showCreateForm.value = false
  } catch (error) {
    creationError.value =
      error instanceof Error ? error.message : 'No fue posible registrar al usuario.'
  } finally {
    savingNewUser.value = false
  }
}

async function handleUpdateUser() {
  if (savingEdit.value || editingUserId.value === null) return

  editError.value = null
  savingEdit.value = true

  const passwordValue = editForm.password.trim()

  const payload: UpdateUserPayload = {
    correo: editForm.correo.trim(),
    password: passwordValue.length > 0 ? passwordValue : null,
    nombreCompleto: editForm.nombreCompleto.trim(),
    medicoId: normalizeMedicoId(editForm.medicoId),
    activo: editForm.activo
  }

  try {
    await store.updateUser(editingUserId.value, payload)
    editingUserId.value = null
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible actualizar al usuario.'
  } finally {
    savingEdit.value = false
  }
}

async function handleDeactivateUser(user: UserAccount) {
  if (actionInProgressId.value || !user.activo) return

  const confirmDeactivate = window.confirm(`¿Deseas desactivar la cuenta ${user.correo}?`)
  if (!confirmDeactivate) {
    return
  }

  actionInProgressId.value = user.id

  try {
    await store.deactivateUser(user.id)
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible desactivar al usuario.'
  } finally {
    actionInProgressId.value = null
  }
}

async function handleReactivateUser(user: UserAccount) {
  if (actionInProgressId.value || user.activo) return

  actionInProgressId.value = user.id

  const payload: UpdateUserPayload = {
    correo: user.correo,
    password: null,
    nombreCompleto: user.nombreCompleto,
    medicoId: user.medicoId ?? null,
    activo: true
  }

  try {
    await store.updateUser(user.id, payload)
  } catch (error) {
    editError.value =
      error instanceof Error ? error.message : 'No fue posible reactivar al usuario.'
  } finally {
    actionInProgressId.value = null
  }
}

function submitSearch() {
  void fetchUsers()
}

watch(includeInactive, () => {
  void fetchUsers()
})

onMounted(() => {
  void store.loadMedics('', true).catch(() => undefined)
  void fetchUsers()
})
</script>

<template>
  <section class="space-y-6">
    <header class="space-y-2">
      <h2 class="text-2xl font-semibold text-white">Administrar usuarios</h2>
      <p class="max-w-3xl text-sm text-slate-300/80">
        Consulta, crea y actualiza las cuentas del personal. Asigna un médico cuando corresponda y controla si la cuenta puede
        acceder al sistema.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
      <form class="flex flex-col gap-3 md:flex-row md:items-end" @submit.prevent="submitSearch">
        <div class="flex-1 space-y-2">
          <label class="text-xs font-semibold uppercase tracking-wide text-slate-400" for="search-users"
            >Buscar</label
          >
          <input
            id="search-users"
            v-model="searchTerm"
            class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
            placeholder="Correo o nombre completo"
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
          {{ showCreateForm ? 'Cerrar formulario' : 'Crear usuario' }}
        </button>
      </form>

      <transition name="fade">
        <div
          v-if="showCreateForm"
          class="mt-6 space-y-4 rounded-3xl border border-slate-800/60 bg-slate-950/60 p-6 text-sm text-slate-200"
        >
          <h3 class="text-base font-semibold text-white">Nuevo usuario</h3>
          <div class="grid gap-4 md:grid-cols-2">
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-correo">Correo electrónico</label>
              <input
                id="nuevo-correo"
                v-model="newUser.correo"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="email"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-nombre">Nombre completo</label>
              <input
                id="nuevo-nombre"
                v-model="newUser.nombreCompleto"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="text"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-password">Contraseña</label>
              <input
                id="nuevo-password"
                v-model="newUser.password"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
                type="password"
              />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-medium text-slate-300" for="nuevo-medico">Médico asignado (opcional)</label>
              <select
                id="nuevo-medico"
                v-model="newUser.medicoId"
                class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/40"
              >
                <option value="">Sin asignar</option>
                <option v-for="medic in availableMedics" :key="medic.id" :value="medic.id">
                  {{ medic.nombreCompleto }}
                </option>
              </select>
            </div>
            <label class="flex items-center gap-2 rounded-2xl border border-slate-800/60 bg-slate-950/60 px-4 py-3 text-xs text-slate-300">
              <input
                v-model="newUser.activo"
                class="h-4 w-4 rounded border-slate-700 bg-slate-900 text-emerald-500 focus:ring-emerald-500"
                type="checkbox"
              />
              Usuario activo
            </label>
          </div>
          <p v-if="creationError" class="rounded-2xl border border-rose-500/40 bg-rose-500/10 px-4 py-3 text-xs text-rose-200">
            {{ creationError }}
          </p>
          <div class="flex flex-col gap-3 pt-2 text-sm font-medium sm:flex-row">
            <button
              class="rounded-2xl border border-emerald-500/60 px-4 py-3 text-emerald-300 transition hover:bg-emerald-500/10 disabled:opacity-60"
              :disabled="savingNewUser"
              type="button"
              @click="handleCreateUser"
            >
              {{ savingNewUser ? 'Guardando...' : 'Guardar usuario' }}
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
        <p v-else-if="isLoading" class="text-sm text-slate-400">Cargando usuarios...</p>
        <p v-else-if="!hasUsers" class="rounded-3xl border border-slate-800/60 bg-slate-950/60 px-4 py-6 text-sm text-slate-300">
          No se encontraron usuarios con los criterios indicados.
        </p>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-800 text-left text-sm text-slate-200">
            <thead>
              <tr class="text-xs uppercase tracking-wide text-slate-400">
                <th class="px-4 py-3">Correo</th>
                <th class="px-4 py-3">Nombre</th>
                <th class="px-4 py-3">Médico asignado</th>
                <th class="px-4 py-3">Estado</th>
                <th class="px-4 py-3 text-right">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-800/60">
              <tr v-for="user in users" :key="user.id" class="hover:bg-slate-900/40">
                <td class="px-4 py-3">
                  <p class="font-semibold text-white">{{ user.correo }}</p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-slate-200">{{ user.nombreCompleto }}</p>
                </td>
                <td class="px-4 py-3">
                  <p class="text-sm text-slate-200">{{ user.medicoNombreCompleto || 'Sin asignar' }}</p>
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold"
                    :class="user.activo ? 'bg-emerald-500/10 text-emerald-300' : 'bg-slate-700/40 text-slate-300'"
                  >
                    {{ user.activo ? 'Activo' : 'Inactivo' }}
                  </span>
                </td>
                <td class="px-4 py-3 text-right">
                  <div class="flex flex-wrap items-center justify-end gap-2 text-xs font-medium">
                    <button
                      class="rounded-2xl border border-slate-700 px-3 py-2 text-slate-200 transition hover:border-sky-500/60 hover:text-sky-300"
                      type="button"
                      @click="startEdit(user)"
                    >
                      Editar
                    </button>
                    <button
                      v-if="user.activo"
                      class="rounded-2xl border border-rose-500/40 px-3 py-2 text-rose-300 transition hover:bg-rose-500/10 disabled:opacity-60"
                      :disabled="actionInProgressId === user.id"
                      type="button"
                      @click="handleDeactivateUser(user)"
                    >
                      {{ actionInProgressId === user.id ? 'Procesando...' : 'Desactivar' }}
                    </button>
                    <button
                      v-else
                      class="rounded-2xl border border-emerald-500/60 px-3 py-2 text-emerald-300 transition hover:bg-emerald-500/10 disabled:opacity-60"
                      :disabled="actionInProgressId === user.id"
                      type="button"
                      @click="handleReactivateUser(user)"
                    >
                      {{ actionInProgressId === user.id ? 'Procesando...' : 'Reactivar' }}
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
        v-if="editingUserId !== null"
        class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6 text-sm text-slate-200"
      >
        <header class="flex items-start justify-between gap-4">
          <div>
            <h3 class="text-lg font-semibold text-white">Editar usuario</h3>
            <p class="text-xs text-slate-400">Modifica los datos de acceso o su estado.</p>
          </div>
          <button class="text-xs text-slate-400 hover:text-white" type="button" @click="cancelEdit">Cerrar</button>
        </header>

        <div class="mt-4 grid gap-4 md:grid-cols-2">
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-correo">Correo electrónico</label>
            <input
              id="editar-correo"
              v-model="editForm.correo"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="email"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-nombre">Nombre completo</label>
            <input
              id="editar-nombre"
              v-model="editForm.nombreCompleto"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="text"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-password">Nueva contraseña (opcional)</label>
            <input
              id="editar-password"
              v-model="editForm.password"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
              type="password"
            />
          </div>
          <div class="space-y-2">
            <label class="text-xs font-medium text-slate-300" for="editar-medico">Médico asignado</label>
            <select
              id="editar-medico"
              v-model="editForm.medicoId"
              class="w-full rounded-2xl border border-slate-700 bg-slate-950/70 px-4 py-3 text-sm text-white focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
            >
              <option value="">Sin asignar</option>
              <option v-for="medic in medics" :key="medic.id" :value="medic.id">
                {{ medic.nombreCompleto }}
              </option>
            </select>
          </div>
          <label class="flex items-center gap-2 rounded-2xl border border-slate-800/60 bg-slate-950/60 px-4 py-3 text-xs text-slate-300">
            <input
              v-model="editForm.activo"
              class="h-4 w-4 rounded border-slate-700 bg-slate-900 text-emerald-500 focus:ring-emerald-500"
              type="checkbox"
            />
            Usuario activo
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
            @click="handleUpdateUser"
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
