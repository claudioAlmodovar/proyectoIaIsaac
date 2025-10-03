export interface Patient {
  id: number
  nombreCompleto: string
  identificador: string
  fechaNacimiento: string
  sexo: 'M' | 'F'
  fechaAlta: string
}

export interface Consultation {
  id: number
  pacienteId: number
  fecha: string
  notas: string
}

export interface ConsultationHistoryEntry extends Consultation {
  paciente: Patient
}

export interface CreatePatientPayload {
  nombreCompleto: string
  identificador: string
  fechaNacimiento: string
  sexo: 'M' | 'F'
}

export interface CreateConsultationPayload {
  pacienteId: number
  notas: string
  fecha?: string
}
