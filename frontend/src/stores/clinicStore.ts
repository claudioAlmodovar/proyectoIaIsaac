import { computed, reactive, ref } from 'vue'
import * as clinicApi from '../services/clinicApi'
import type {
  Consultation,
  ConsultationHistoryEntry,
  CreateConsultationPayload,
  CreatePatientPayload,
  Patient
} from '../types'

const patientsState = ref<Patient[]>([])
const consultationHistoryState = ref<ConsultationHistoryEntry[]>([])
const patientsCache = reactive(new Map<number, Patient>())
const consultationsByPatientCache = reactive(new Map<number, Consultation[]>())

export function useClinicStore() {
  const patients = computed(() => patientsState.value)
  const consultationHistory = computed(() => consultationHistoryState.value)

  async function searchPatients(term: string) {
    const results = await clinicApi.searchPatients(term)
    patientsState.value = results

    results.forEach((patient) => {
      patientsCache.set(patient.id, patient)
    })

    return results
  }

  async function createPatient(payload: CreatePatientPayload) {
    const patient = await clinicApi.createPatient(payload)

    patientsCache.set(patient.id, patient)
    patientsState.value = [patient, ...patientsState.value.filter((item) => item.id !== patient.id)]

    return patient
  }

  async function getPatientById(id: number) {
    if (patientsCache.has(id)) {
      return patientsCache.get(id) ?? null
    }

    const patient = await clinicApi.getPatientById(id)
    if (patient) {
      patientsCache.set(patient.id, patient)
      if (!patientsState.value.some((item) => item.id === patient.id)) {
        patientsState.value = [patient, ...patientsState.value]
      }
    }

    return patient
  }

  async function getConsultationsByPatient(patientId: number, limit = 5) {
    const consultations = await clinicApi.getConsultationsByPatient(patientId, limit)
    consultationsByPatientCache.set(patientId, consultations)
    return consultations
  }

  async function createConsultation(payload: CreateConsultationPayload) {
    const consultation = await clinicApi.createConsultation(payload)

    const cached = consultationsByPatientCache.get(payload.pacienteId)
    if (cached) {
      const maxItems = Math.max(cached.length, 1)
      consultationsByPatientCache.set(
        payload.pacienteId,
        [consultation, ...cached].slice(0, maxItems)
      )
    }

    return consultation
  }

  async function loadConsultationHistory(startDate?: string, endDate?: string) {
    const history = await clinicApi.getConsultationsHistory(startDate, endDate)
    consultationHistoryState.value = history

    history.forEach((entry) => {
      patientsCache.set(entry.paciente.id, entry.paciente)
    })

    return history
  }

  function getCachedConsultationsByPatient(patientId: number) {
    return consultationsByPatientCache.get(patientId) ?? []
  }

  return {
    patients,
    consultationHistory,
    searchPatients,
    createPatient,
    getPatientById,
    getConsultationsByPatient,
    createConsultation,
    loadConsultationHistory,
    getCachedConsultationsByPatient
  }
}
