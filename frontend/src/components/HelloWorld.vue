<script setup lang="ts">
interface Props {
  msg: string
}

defineProps<Props>()

const features = [
  {
    title: 'Configuración moderna',
    description:
      'Vite proporciona recarga instantánea y compilaciones rápidas para mejorar tu productividad diaria.'
  },
  {
    title: 'TypeScript listo para usar',
    description:
      'Obtén tipos estrictos y autocompletado para mantener tu código robusto a medida que crece.'
  },
  {
    title: 'Estilos con Tailwind CSS',
    description:
      'Utiliza utilidades listas para crear diseños consistentes sin salir del flujo de trabajo.'
  }
]
</script>

<template>
  <section class="space-y-8 rounded-3xl border border-slate-800 bg-slate-950/60 p-10 shadow-2xl shadow-slate-950">
    <h2 class="text-2xl font-semibold text-slate-100 md:text-3xl">{{ msg }}</h2>
    <div class="grid gap-8 md:grid-cols-3">
      <article
        v-for="feature in features"
        :key="feature.title"
        class="space-y-3 rounded-2xl border border-slate-800 bg-slate-900/60 p-6 text-left"
      >
        <h3 class="text-xl font-semibold text-teal-300">{{ feature.title }}</h3>
        <p class="text-sm leading-relaxed text-slate-300">{{ feature.description }}</p>
      </article>
    </div>
  </section>
</template>
