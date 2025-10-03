import { computed, ref } from 'vue'
import * as clinicApi from '../services/clinicApi'
import type {
  CreateMedicPayload,
  CreateUserPayload,
  Medic,
  UpdateMedicPayload,
  UpdateUserPayload,
  UserAccount
} from '../types'

const medicsState = ref<Medic[]>([])
const usersState = ref<UserAccount[]>([])

export function useAdminStore() {
  const medics = computed(() => medicsState.value)
  const users = computed(() => usersState.value)

  async function loadMedics(searchTerm = '', includeInactive = false) {
    const medics = await clinicApi.getMedics(searchTerm, includeInactive)
    medicsState.value = medics
    return medics
  }

  async function createMedic(payload: CreateMedicPayload) {
    const medic = await clinicApi.createMedic(payload)
    medicsState.value = [medic, ...medicsState.value.filter((item) => item.id !== medic.id)]
    return medic
  }

  async function updateMedic(id: number, payload: UpdateMedicPayload) {
    const medic = await clinicApi.updateMedic(id, payload)
    medicsState.value = medicsState.value.map((item) => (item.id === id ? medic : item))
    return medic
  }

  async function deactivateMedic(id: number) {
    await clinicApi.disableMedic(id)
    medicsState.value = medicsState.value.map((item) =>
      item.id === id ? { ...item, activo: false } : item
    )
  }

  async function loadUsers(searchTerm = '', includeInactive = false) {
    const users = await clinicApi.getUsers(searchTerm, includeInactive)
    usersState.value = users
    return users
  }

  async function createUser(payload: CreateUserPayload) {
    const user = await clinicApi.createUser(payload)
    usersState.value = [user, ...usersState.value.filter((item) => item.id !== user.id)]
    return user
  }

  async function updateUser(id: number, payload: UpdateUserPayload) {
    const user = await clinicApi.updateUser(id, payload)
    usersState.value = usersState.value.map((item) => (item.id === id ? user : item))
    return user
  }

  async function deactivateUser(id: number) {
    await clinicApi.disableUser(id)
    usersState.value = usersState.value.map((item) =>
      item.id === id ? { ...item, activo: false } : item
    )
  }

  return {
    medics,
    users,
    loadMedics,
    createMedic,
    updateMedic,
    deactivateMedic,
    loadUsers,
    createUser,
    updateUser,
    deactivateUser
  }
}
