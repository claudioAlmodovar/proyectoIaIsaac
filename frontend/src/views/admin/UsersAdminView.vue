<script setup lang="ts">
</script>

<template>
  <section class="space-y-6">
    <header class="space-y-2">
      <h2 class="text-2xl font-semibold text-white">Administrar usuarios</h2>
      <p class="max-w-2xl text-sm text-slate-300/80">
        Desde este módulo podrás consultar, crear, actualizar y desactivar cuentas de acceso para el personal de la clínica.
        Vincula los usuarios con el catálogo de médicos cuando corresponda.
      </p>
    </header>

    <div class="rounded-3xl border border-slate-800/60 bg-slate-900/60 p-6 text-sm text-slate-300/80">
      <p>
        El desarrollo del CRUD se encuentra en progreso. Mientras tanto, puedes revisar la configuración de usuarios desde la
        base de datos y vincularlos con médicos usando el campo <span class="font-semibold text-slate-200">IdMedico</span>.
      </p>
      <p class="mt-3">
        Una vez que se integren los servicios correspondientes, aquí verás la tabla de usuarios con opciones para crear nuevos
        accesos y editar los existentes.
      </p>
    </div>
  </section>
</template>
