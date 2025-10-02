<script setup lang="ts">
import HelloWorld from './components/HelloWorld.vue'
</script>

<template>
  <main class="min-h-screen bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900">
    <section class="mx-auto flex max-w-4xl flex-col gap-12 px-6 py-16 text-center">
      <header class="space-y-4">
        <h1 class="text-4xl font-bold md:text-5xl">Bienvenido a Vue 3 + TypeScript + Tailwind CSS</h1>
        <p class="text-lg text-slate-300">
          Este proyecto inicial incluye configuración lista para desarrollar interfaces modernas utilizando Vite.
        </p>
      </header>
      <HelloWorld msg="Comienza a construir tu aplicación" />
    </section>
  </main>
</template>
