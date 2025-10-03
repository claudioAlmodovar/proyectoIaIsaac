<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { getRandomPhrase } from '../constants/motivationalPhrases'
import { useSession } from '../composables/useSession'

const router = useRouter()
const route = useRoute()
const { currentUser, logout } = useSession()

const motivationalPhrase = ref(getRandomPhrase())

const activeRouteName = computed(() => route.name as string | undefined)

function isActive(name: string) {
  if (!activeRouteName.value) return false
  if (activeRouteName.value === name) return true
  if (name === 'consultas-buscar' && activeRouteName.value === 'consultas-nueva') return true
  return false
}

watch(
  () => route.fullPath,
  () => {
    motivationalPhrase.value = getRandomPhrase()
  }
)

const userGreeting = computed(() => {
  if (!currentUser.value) return 'Bienvenido'
  const [nombre] = currentUser.value.nombreCompleto.split(' ')
  return `Hola, ${nombre}`
})

function handleLogout() {
  logout()
  router.push({ name: 'login' })
}

const navigation = [
  {
    title: 'Consultas',
    icon: '🩺',
    items: [
      { label: 'Consultar', name: 'consultas-buscar' },
      { label: 'Historial de consultas', name: 'consultas-historial' }
    ]
  },
  {
    title: 'Administración',
    icon: '🗂️',
    items: [
      { label: 'Gestión de pacientes', name: 'consultas-buscar', disabled: true },
      { label: 'Inventario clínico', name: 'dashboard', disabled: true }
    ]
  }
]
</script>

<template>
  <div class="min-h-screen bg-slate-950 text-slate-100">
    <header class="border-b border-slate-800 bg-slate-900/70 backdrop-blur">
      <div class="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-6 px-6 py-6">
        <div>
          <p class="text-sm uppercase tracking-[0.35em] text-sky-400/80">Clínica Mágica</p>
          <h1 class="mt-1 text-2xl font-semibold text-white">{{ userGreeting }}</h1>
          <p class="mt-1 max-w-2xl text-sm text-slate-300/80">{{ motivationalPhrase }}</p>
        </div>
        <button
          class="inline-flex items-center gap-2 rounded-full border border-slate-700/60 px-4 py-2 text-sm font-medium text-slate-200 transition hover:border-rose-400/60 hover:text-rose-200"
          type="button"
          @click="handleLogout"
        >
          <span>Salir</span>
        </button>
      </div>
    </header>

    <div class="mx-auto flex max-w-7xl flex-col gap-6 px-6 py-8 lg:flex-row">
      <aside class="lg:w-64">
        <nav class="space-y-6 rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6">
          <div v-for="section in navigation" :key="section.title" class="space-y-3">
            <p class="text-xs font-semibold uppercase tracking-[0.25em] text-slate-400/70">
              <span class="mr-2">{{ section.icon }}</span>{{ section.title }}
            </p>
            <ul class="space-y-2 text-sm">
              <li v-for="item in section.items" :key="item.label">
                <RouterLink
                  v-if="!item.disabled"
                  :to="{ name: item.name }"
                  class="flex items-center justify-between rounded-2xl border border-transparent px-4 py-3 font-medium text-slate-200 transition hover:border-sky-500/50 hover:bg-slate-800/60"
                  :class="{ 'border-sky-500/60 bg-slate-800/60': isActive(item.name) }"
                >
                  {{ item.label }}
                  <span aria-hidden="true">→</span>
                </RouterLink>
                <button
                  v-else
                  class="flex w-full items-center justify-between rounded-2xl border border-slate-800/60 px-4 py-3 font-medium text-slate-500"
                  disabled
                  type="button"
                >
                  {{ item.label }}
                  <span aria-hidden="true">🔒</span>
                </button>
              </li>
            </ul>
          </div>
        </nav>
      </aside>

      <main class="flex-1 pb-16">
        <RouterView />
      </main>
    </div>
  </div>
</template>
