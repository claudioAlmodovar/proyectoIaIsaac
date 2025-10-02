<script setup lang="ts">
import LoginForm from './components/LoginForm.vue'
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-950 via-sky-950 to-slate-900 text-sky-50">
    <div
      class="mx-auto flex min-h-screen w-full max-w-6xl flex-col items-center justify-center gap-16 px-6 py-16 lg:flex-row lg:py-24"
    >
      <section class="flex-1 space-y-6 text-center lg:text-left">
        <p class="text-xs uppercase tracking-[0.35em] text-sky-400/80">Clínica Mágica</p>
        <h1 class="text-3xl font-semibold leading-tight text-white md:text-4xl">
          Plataforma integral para el control operativo de tu clínica
        </h1>
        <p class="mx-auto max-w-xl text-base text-sky-100/80 lg:mx-0">
          Gestiona pacientes, agenda consultas y supervisa tu inventario con flujos que se adaptan a cualquier
          dispositivo. Inicia sesión para continuar con tus labores diarias.
        </p>
        <ul class="mx-auto grid max-w-xl gap-4 text-left text-sm text-slate-200/80 sm:grid-cols-2 lg:mx-0">
          <li class="flex items-start gap-3 rounded-2xl border border-slate-800/60 bg-slate-900/40 p-4">
            <span class="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-full bg-emerald-500/20 text-xs font-semibold text-emerald-300">1</span>
            <span>Protocolos de seguridad y auditoría diseñados para equipos médicos multidisciplinarios.</span>
          </li>
          <li class="flex items-start gap-3 rounded-2xl border border-slate-800/60 bg-slate-900/40 p-4">
            <span class="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-full bg-sky-500/20 text-xs font-semibold text-sky-300">2</span>
            <span>Interfaz responsiva optimizada para trabajar desde consultorios, tablets o dispositivos móviles.</span>
          </li>
          <li class="flex items-start gap-3 rounded-2xl border border-slate-800/60 bg-slate-900/40 p-4 sm:col-span-2">
            <span class="mt-0.5 inline-flex h-6 w-6 items-center justify-center rounded-full bg-violet-500/20 text-xs font-semibold text-violet-200">3</span>
            <span>Integración directa con servicios internos de la clínica para un flujo de información sin fricciones.</span>
          </li>
        </ul>
      </section>

      <LoginForm />
    </div>
  </div>
</template>
