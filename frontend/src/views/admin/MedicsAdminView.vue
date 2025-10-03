<script setup lang="ts">
</script>

<template>
  <section class="space-y-6">
    <header class="space-y-2">
      <h2 class="text-2xl font-semibold text-white">Administrar médicos</h2>
      <p class="max-w-2xl text-sm text-slate-300/80">
        Gestiona el catálogo de médicos activos en la clínica. Cada médico puede asociarse a múltiples usuarios del sistema,
        asegurando que las consultas queden registradas con la persona correcta.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6 text-sm text-slate-300/80">
      <p>
        Este módulo mostrará próximamente el listado de médicos junto con opciones para agregar nuevos especialistas, editar sus
        datos de contacto y actualizar la información de su cédula profesional.
      </p>
      <p class="mt-3">
        Mientras tanto, puedes utilizar el script de base de datos actualizado para cargar médicos de ejemplo y vincularlos con
        los usuarios que tienen asignado el campo <span class="font-semibold text-slate-200">IdMedico</span>.
      </p>
    </div>
  </section>
</template>
