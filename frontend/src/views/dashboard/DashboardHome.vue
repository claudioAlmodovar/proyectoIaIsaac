<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useSession } from '../../composables/useSession'

const { currentUser } = useSession()

const userName = computed(() => currentUser.value?.nombreCompleto ?? 'Equipo médico')
</script>

<template>
  <section class="space-y-10">
    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-8">
      <h2 class="text-2xl font-semibold text-white">Panel principal</h2>
      <p class="mt-2 max-w-2xl text-sm text-slate-300/80">
        Bienvenido al centro de operaciones de Clínica Mágica. Desde aquí podrás gestionar consultas, revisar historiales y
        mantener tu agenda actualizada. Estamos listos para apoyarte en tu jornada clínica, {{ userName }}.
      </p>
    </div>

    <div class="grid gap-6 lg:grid-cols-2">
      <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-8">
        <div class="mb-6 flex items-center justify-between">
          <h3 class="text-lg font-semibold text-white">Consultas</h3>
          <span class="text-2xl" aria-hidden="true">🩺</span>
        </div>
        <ul class="space-y-4 text-sm">
          <li>
            <RouterLink
              :to="{ name: 'consultas-buscar' }"
              class="flex items-center justify-between rounded-2xl border border-slate-800/60 px-4 py-4 font-medium text-slate-200 transition hover:border-sky-500/60 hover:bg-slate-800/60"
            >
              <span>Consultar pacientes dados de alta</span>
              <span aria-hidden="true">→</span>
            </RouterLink>
          </li>
          <li>
            <RouterLink
              :to="{ name: 'consultas-historial' }"
              class="flex items-center justify-between rounded-2xl border border-slate-800/60 px-4 py-4 font-medium text-slate-200 transition hover:border-sky-500/60 hover:bg-slate-800/60"
            >
              <span>Historial de consultas</span>
              <span aria-hidden="true">→</span>
            </RouterLink>
          </li>
        </ul>
      </div>

      <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-8">
        <div class="mb-6 flex items-center justify-between">
          <h3 class="text-lg font-semibold text-white">Administración</h3>
          <span class="text-2xl" aria-hidden="true">🗂️</span>
        </div>
        <ul class="space-y-4 text-sm">
          <li>
            <RouterLink
              :to="{ name: 'admin-usuarios' }"
              class="flex items-center justify-between rounded-2xl border border-slate-800/60 px-4 py-4 font-medium text-slate-200 transition hover:border-sky-500/60 hover:bg-slate-800/60"
            >
              <span>CRUD de usuarios</span>
              <span aria-hidden="true">→</span>
            </RouterLink>
          </li>
          <li>
            <RouterLink
              :to="{ name: 'admin-medicos' }"
              class="flex items-center justify-between rounded-2xl border border-slate-800/60 px-4 py-4 font-medium text-slate-200 transition hover:border-sky-500/60 hover:bg-slate-800/60"
            >
              <span>CRUD de médicos</span>
              <span aria-hidden="true">→</span>
            </RouterLink>
          </li>
        </ul>
      </div>
    </div>
  </section>
</template>
