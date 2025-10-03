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
