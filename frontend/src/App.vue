<script setup lang="ts">
import HelloWorld from './components/HelloWorld.vue'
</script>

<template>
  <main
    class="min-h-screen bg-gradient-to-br from-sky-950 via-blue-950 to-slate-950 text-sky-50"
  >
    <section class="mx-auto flex max-w-5xl flex-col gap-16 px-6 py-20 text-center">
      <header class="space-y-6">
        <p class="text-sm uppercase tracking-[0.4em] text-sky-300/80">Sistema Farma Leado</p>
        <h1 class="text-4xl font-bold leading-tight md:text-5xl">
          Bienvenido a la plataforma operativa de Farma Leado
        </h1>
        <p class="mx-auto max-w-3xl text-lg text-sky-100/80">
          Centraliza tus procesos farmacéuticos con herramientas diseñadas para equipos modernos.
          Controla inventario, pedidos y cumplimiento regulatorio desde un único panel intuitivo.
        </p>
        <div class="flex flex-wrap items-center justify-center gap-4">
          <button
            class="rounded-full bg-sky-500 px-8 py-3 text-base font-semibold text-slate-950 shadow-lg shadow-blue-900/40 transition hover:-translate-y-0.5 hover:bg-sky-400"
            type="button"
          >
            Explorar soluciones
          </button>
          <span class="text-sm text-sky-200/70">
            Descubre cómo Farma Leado simplifica la gestión farmacéutica.
          </span>
        </div>
      </header>
      <HelloWorld msg="Tu socio digital para una gestión farmacéutica confiable" />
      <footer class="space-y-3 text-sm text-sky-200/60">
        <p>
          Plataforma ficticia creada para demostrar un entorno de trabajo moderno con Vue, TypeScript y
          Tailwind CSS.
        </p>
        <p>
          Mantente atento a futuras funcionalidades como gestión de usuarios, reportes avanzados y flujos de
          aprobación.
        </p>
      </footer>
    </section>
  </main>
</template>
