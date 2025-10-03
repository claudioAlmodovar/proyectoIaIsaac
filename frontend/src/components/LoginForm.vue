<template>
  <section
    class="w-full max-w-md rounded-3xl border border-slate-800/60 bg-slate-900/70 p-8 shadow-xl shadow-slate-950/50 backdrop-blur"
  >
    <header class="mb-8 space-y-1 text-center">
      <h2 class="text-2xl font-semibold text-white">Inicia sesión</h2>
      <p class="text-sm text-slate-300/80">
        Accede al panel administrativo de Clínica Mágica con tus credenciales asignadas.
      </p>
    </header>

    <form class="space-y-6" @submit.prevent="onSubmit">
      <div class="space-y-2">
        <label class="text-sm font-medium text-slate-200" for="email">Correo electrónico</label>
        <input
          id="email"
          v-model="email"
          autocomplete="email"
          class="w-full rounded-2xl border border-slate-700 bg-slate-950/60 px-4 py-3 text-sm text-white transition focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
          placeholder="medico@clinicamagica.mx"
          required
          type="email"
        />
      </div>

      <div class="space-y-2">
        <label class="text-sm font-medium text-slate-200" for="password">Contraseña</label>
        <input
          id="password"
          v-model="password"
          autocomplete="current-password"
          class="w-full rounded-2xl border border-slate-700 bg-slate-950/60 px-4 py-3 text-sm text-white transition focus:border-sky-500 focus:outline-none focus:ring-2 focus:ring-sky-500/60"
          placeholder="••••••••"
          required
          type="password"
        />
      </div>

      <button
        :disabled="isSubmitting"
        class="flex w-full items-center justify-center gap-2 rounded-2xl bg-sky-500 px-4 py-3 text-sm font-semibold text-slate-950 transition hover:bg-sky-400 focus:outline-none focus:ring-2 focus:ring-sky-500/60 disabled:cursor-not-allowed disabled:bg-sky-500/60"
        type="submit"
      >
        <svg
          v-if="isSubmitting"
          class="h-4 w-4 animate-spin text-slate-900"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-30" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path
            class="opacity-80"
            d="M4 12a8 8 0 018-8"
            stroke="currentColor"
            stroke-linecap="round"
            stroke-width="4"
          ></path>
        </svg>
        <span>{{ isSubmitting ? 'Validando acceso…' : 'Ingresar' }}</span>
      </button>
    </form>

    <transition name="fade">
      <p
        v-if="feedback"
        :class="[
          'mt-6 rounded-2xl px-4 py-3 text-sm font-medium transition',
          feedback.type === 'success'
            ? 'bg-emerald-500/20 text-emerald-200'
            : 'bg-rose-500/10 text-rose-200'
        ]"
        role="alert"
      >
        {{ feedback.message }}
      </p>
    </transition>

    <footer class="mt-8 space-y-2 text-xs text-slate-400">
      <p>
        ¿Problemas para iniciar sesión? Contacta al administrador de sistemas para restablecer tus credenciales.
      </p>
      <p>
        Al continuar aceptas las políticas de privacidad internas de Clínica Mágica y el uso adecuado de la plataforma.
      </p>
    </footer>
  </section>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useSession } from '../composables/useSession'

const email = ref('')
const password = ref('')
const isSubmitting = ref(false)
const state = reactive<{ status: 'idle' | 'success' | 'error'; message: string }>({
  status: 'idle',
  message: ''
})

const router = useRouter()
const { login } = useSession()

const feedback = computed(() => {
  if (state.status === 'idle') return null
  return {
    type: state.status,
    message: state.message
  }
})

async function onSubmit() {
  if (isSubmitting.value) return

  state.status = 'idle'
  state.message = ''
  isSubmitting.value = true

  try {
    const response = await login(email.value, password.value)
    state.status = 'success'
    state.message = response.message ?? '¡Bienvenido de nuevo!'
    password.value = ''
    router.push({ name: 'dashboard' })
  } catch (error) {
    state.status = 'error'
    state.message =
      error instanceof Error ? error.message : 'Ocurrió un error inesperado al validar tus credenciales.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease-in-out, transform 0.2s ease-in-out;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
</style>
