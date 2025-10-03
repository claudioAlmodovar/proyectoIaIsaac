import type {
  Consultation,
  ConsultationHistoryEntry,
  CreateConsultationPayload,
  CreateMedicPayload,
  CreatePatientPayload,
  CreateUserPayload,
  Medic,
  Patient,
  UpdateMedicPayload,
  UpdateUserPayload,
  UserAccount
} from '../types'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://localhost:7240'

type FetchOptions = RequestInit & { skipJsonParsing?: boolean }

type ApiErrorResponse = {
  message?: string
  error?: string
}

async function request<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const { skipJsonParsing, headers, ...rest } = options
  let response: Response

  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      headers: {
        'Content-Type': 'application/json',
        ...(headers ?? {})
      },
      ...rest
    })
  } catch (error) {
    throw new Error('No se pudo establecer comunicación con el servicio. Intenta nuevamente más tarde.')
  }

  if (!response.ok) {
    let message = 'Ocurrió un error al procesar la solicitud.'

    try {
      const errorBody = (await response.json()) as ApiErrorResponse
      message = errorBody.message ?? errorBody.error ?? message
    } catch (error) {
      // Ignorar errores al leer el cuerpo
    }

    throw new Error(message)
  }

  if (skipJsonParsing || response.status === 204) {
    return undefined as T
  }

  return (await response.json()) as T
}

export async function searchPatients(searchTerm: string): Promise<Patient[]> {
  const query = new URLSearchParams()
  if (searchTerm.trim()) {
    query.set('search', searchTerm.trim())
  }

  const queryString = query.toString()
  const path = queryString ? `/patients?${queryString}` : '/patients'
  return request<Patient[]>(path, { method: 'GET' })
}

export async function createPatient(payload: CreatePatientPayload): Promise<Patient> {
  return request<Patient>('/patients', {
    method: 'POST',
    body: JSON.stringify(payload)
  })
}

export async function getPatientById(id: number): Promise<Patient | null> {
  try {
    return await request<Patient>(`/patients/${id}`, { method: 'GET' })
  } catch (error) {
    if (error instanceof Error && error.message.toLowerCase().includes('no encontrado')) {
      return null
    }

    throw error
  }
}

export async function getConsultationsByPatient(
  patientId: number,
  limit = 5
): Promise<Consultation[]> {
  const query = new URLSearchParams({ limit: String(limit) })
  return request<Consultation[]>(`/patients/${patientId}/consultations?${query.toString()}`, {
    method: 'GET'
  })
}

export async function createConsultation(payload: CreateConsultationPayload): Promise<Consultation> {
  return request<Consultation>('/consultations', {
    method: 'POST',
    body: JSON.stringify(payload)
  })
}

export async function getConsultationsHistory(
  startDate?: string,
  endDate?: string
): Promise<ConsultationHistoryEntry[]> {
  const query = new URLSearchParams()

  if (startDate?.trim()) {
    query.set('startDate', startDate)
  }

  if (endDate?.trim()) {
    query.set('endDate', endDate)
  }

  const queryString = query.toString()
  const path = queryString ? `/consultations?${queryString}` : '/consultations'
  return request<ConsultationHistoryEntry[]>(path, { method: 'GET' })
}

export async function getMedics(searchTerm?: string, includeInactive = false): Promise<Medic[]> {
  const query = new URLSearchParams()

  if (searchTerm?.trim()) {
    query.set('search', searchTerm.trim())
  }

  if (includeInactive) {
    query.set('includeInactive', 'true')
  }

  const queryString = query.toString()
  const path = queryString ? `/medics?${queryString}` : '/medics'
  return request<Medic[]>(path, { method: 'GET' })
}

export async function createMedic(payload: CreateMedicPayload): Promise<Medic> {
  return request<Medic>('/medics', {
    method: 'POST',
    body: JSON.stringify(payload)
  })
}

export async function updateMedic(id: number, payload: UpdateMedicPayload): Promise<Medic> {
  return request<Medic>(`/medics/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload)
  })
}

export async function disableMedic(id: number): Promise<void> {
  await request(`/medics/${id}`, { method: 'DELETE', skipJsonParsing: true })
}

export async function getUsers(searchTerm?: string, includeInactive = false): Promise<UserAccount[]> {
  const query = new URLSearchParams()

  if (searchTerm?.trim()) {
    query.set('search', searchTerm.trim())
  }

  if (includeInactive) {
    query.set('includeInactive', 'true')
  }

  const queryString = query.toString()
  const path = queryString ? `/users?${queryString}` : '/users'
  return request<UserAccount[]>(path, { method: 'GET' })
}

export async function createUser(payload: CreateUserPayload): Promise<UserAccount> {
  return request<UserAccount>('/users', {
    method: 'POST',
    body: JSON.stringify(payload)
  })
}

export async function updateUser(id: number, payload: UpdateUserPayload): Promise<UserAccount> {
  return request<UserAccount>(`/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload)
  })
}

export async function disableUser(id: number): Promise<void> {
  await request(`/users/${id}`, { method: 'DELETE', skipJsonParsing: true })
}
