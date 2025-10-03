import { computed, ref } from 'vue'

type User = {
  id: number
  correo: string
  nombreCompleto: string
}

type LoginResponse = {
  message: string
  usuario?: User
}

const currentUser = ref<User | null>(null)
const lastWelcomeMessage = ref<string>('')

export function useSession() {
  const isAuthenticated = computed(() => currentUser.value !== null)

  async function login(email: string, password: string) {
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'https://localhost:7240'

    let response: Response

    try {
      response = await fetch(`${apiBaseUrl}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email: email.trim(),
          password
        })
      })
    } catch (error) {
      throw new Error('No fue posible conectar con el servicio de autenticación. Intenta nuevamente.')
    }

    const data = (await response.json()) as LoginResponse

    if (!response.ok) {
      throw new Error(data?.message ?? 'No fue posible validar tus credenciales.')
    }

    const user =
      data.usuario ?? ({
        id: Date.now(),
        correo: email,
        nombreCompleto: email.split('@')[0] ?? 'Usuario'
      } satisfies User)

    currentUser.value = user
    lastWelcomeMessage.value = data.message ?? '¡Bienvenido de nuevo!'

    return data
  }

  function logout() {
    currentUser.value = null
    lastWelcomeMessage.value = ''
  }

  return {
    currentUser,
    isAuthenticated,
    lastWelcomeMessage,
    login,
    logout
  }
}
