import { computed, reactive } from 'vue'
import type { Consultation, Patient } from '../types'

const initialPatients: Patient[] = [
  {
    id: 1,
    nombreCompleto: 'María López Hernández',
    identificador: 'CLM-001',
    fechaNacimiento: '1987-03-15',
    sexo: 'F',
    fechaAlta: '2024-01-03'
  },
  {
    id: 2,
    nombreCompleto: 'Jorge Ramírez Castillo',
    identificador: 'CLM-002',
    fechaNacimiento: '1979-11-02',
    sexo: 'M',
    fechaAlta: '2023-12-18'
  },
  {
    id: 3,
    nombreCompleto: 'Paulina Sánchez Ríos',
    identificador: 'CLM-003',
    fechaNacimiento: '1992-07-28',
    sexo: 'F',
    fechaAlta: '2023-11-25'
  }
]

const initialConsultations: Consultation[] = [
  {
    id: 1,
    pacienteId: 1,
    fecha: new Date().toISOString(),
    notas: 'Control general sin novedades. Se recomienda continuar con dieta equilibrada y ejercicio moderado.'
  },
  {
    id: 2,
    pacienteId: 2,
    fecha: new Date(Date.now() - 1000 * 60 * 60 * 24 * 3).toISOString(),
    notas: 'Revisión de seguimiento para hipertensión. Ajuste de medicación nocturna.'
  },
  {
    id: 3,
    pacienteId: 1,
    fecha: new Date(Date.now() - 1000 * 60 * 60 * 24 * 14).toISOString(),
    notas: 'Se registra mejoría en niveles de glucosa. Mantener monitoreo cada 15 días.'
  }
]

const state = reactive({
  patients: [...initialPatients],
  consultations: [...initialConsultations],
  nextPatientId: initialPatients.length + 1,
  nextConsultationId: initialConsultations.length + 1
})

export function useClinicStore() {
  const patients = computed(() => state.patients)
  const consultations = computed(() =>
    [...state.consultations].sort((a, b) => new Date(b.fecha).getTime() - new Date(a.fecha).getTime())
  )

  function searchPatients(term: string) {
    const normalizedTerm = term.trim().toLowerCase()
    if (!normalizedTerm) {
      return state.patients
    }

    return state.patients.filter((patient) => {
      const fullName = patient.nombreCompleto.toLowerCase()
      const identifier = patient.identificador.toLowerCase()
      return fullName.includes(normalizedTerm) || identifier.includes(normalizedTerm)
    })
  }

  function addPatient(payload: Omit<Patient, 'id' | 'fechaAlta'> & { fechaAlta?: string }) {
    const newPatient: Patient = {
      id: state.nextPatientId++,
      fechaAlta: payload.fechaAlta ?? new Date().toISOString().slice(0, 10),
      nombreCompleto: payload.nombreCompleto,
      identificador: payload.identificador,
      fechaNacimiento: payload.fechaNacimiento,
      sexo: payload.sexo
    }

    state.patients.push(newPatient)
    return newPatient
  }

  function addConsultation(payload: Omit<Consultation, 'id' | 'fecha'> & { fecha?: string }) {
    const newConsultation: Consultation = {
      id: state.nextConsultationId++,
      pacienteId: payload.pacienteId,
      notas: payload.notas,
      fecha: payload.fecha ?? new Date().toISOString()
    }

    state.consultations.push(newConsultation)
    return newConsultation
  }

  function findPatientById(id: number) {
    return state.patients.find((patient) => patient.id === id) ?? null
  }

  function findConsultationsByPatient(id: number) {
    return state.consultations
      .filter((consultation) => consultation.pacienteId === id)
      .sort((a, b) => new Date(b.fecha).getTime() - new Date(a.fecha).getTime())
  }

  return {
    patients,
    consultations,
    searchPatients,
    addPatient,
    addConsultation,
    findPatientById,
    findConsultationsByPatient
  }
}
