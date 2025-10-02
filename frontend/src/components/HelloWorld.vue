<script setup lang="ts">
interface Props {
  msg: string
}

defineProps<Props>()

const features = [
  {
    title: 'Inventario inteligente',
    description:
      'Controla existencias y fechas de caducidad en tiempo real con alertas automáticas para cada sucursal.'
  },
  {
    title: 'Trazabilidad regulatoria',
    description:
      'Genera reportes y bitácoras listos para auditorías, asegurando el cumplimiento de normativas sanitarias.'
  },
  {
    title: 'Analítica accionable',
    description:
      'Visualiza ventas, demanda y desempeño de proveedores para decidir con datos confiables.'
  }
]
</script>

<template>
  <section
    class="space-y-8 rounded-3xl border border-blue-900/60 bg-blue-950/60 p-10 text-left shadow-2xl shadow-blue-950/40 backdrop-blur"
  >
    <div class="space-y-3 text-center md:text-left">
      <h2 class="text-2xl font-semibold text-sky-100 md:text-3xl">{{ msg }}</h2>
      <p class="text-base text-sky-200/80">
        Las herramientas de Clinica Magica están diseñadas para conectar cada área del negocio farmacéutico y
        mantener la operación bajo control.
      </p>
    </div>
    <div class="grid gap-8 md:grid-cols-3">
      <article
        v-for="feature in features"
        :key="feature.title"
        class="space-y-3 rounded-2xl border border-sky-900/60 bg-slate-950/40 p-6"
      >
        <h3 class="text-xl font-semibold text-sky-300">{{ feature.title }}</h3>
        <p class="text-sm leading-relaxed text-sky-100/80">{{ feature.description }}</p>
      </article>
    </div>
  </section>
</template>
