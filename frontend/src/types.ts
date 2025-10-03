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
  fechaNacimiento: string
  sexo: 'M' | 'F'
}

export interface CreateConsultationPayload {
  pacienteId: number
  notas: string
  fecha?: string
}

export interface Medic {
  id: number
  primerNombre: string
  segundoNombre?: string | null
  apellidoPaterno: string
  apellidoMaterno?: string | null
  cedula: string
  especialidad: string
  email: string
  telefono?: string | null
  activo: boolean
  nombreCompleto: string
}

export interface CreateMedicPayload {
  primerNombre: string
  segundoNombre?: string | null
  apellidoPaterno: string
  apellidoMaterno?: string | null
  cedula: string
  especialidad: string
  email: string
  telefono?: string | null
}

export interface UpdateMedicPayload extends CreateMedicPayload {
  activo: boolean
}

export interface UserAccount {
  id: number
  correo: string
  nombreCompleto: string
  activo: boolean
  medicoId?: number | null
  medicoNombreCompleto?: string | null
}

export interface CreateUserPayload {
  correo: string
  password: string
  nombreCompleto: string
  medicoId?: number | null
  activo: boolean
}

export interface UpdateUserPayload {
  correo: string
  password?: string | null
  nombreCompleto: string
  medicoId?: number | null
  activo: boolean
}
