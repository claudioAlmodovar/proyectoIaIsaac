import { createRouter, createWebHistory } from 'vue-router'
import { useSession } from '../composables/useSession'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      redirect: '/login'
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue')
    },
    {
      path: '/app',
      component: () => import('../layouts/DashboardLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('../views/dashboard/DashboardHome.vue')
        },
        {
          path: 'consultas',
          name: 'consultas',
          redirect: { name: 'consultas-buscar' }
        },
        {
          path: 'consultas/buscar',
          name: 'consultas-buscar',
          component: () => import('../views/consultations/ConsultationSearchView.vue')
        },
        {
          path: 'consultas/pacientes/:patientId/nueva',
          name: 'consultas-nueva',
          component: () => import('../views/consultations/ConsultationFormView.vue'),
          props: true
        },
        {
          path: 'consultas/historial',
          name: 'consultas-historial',
          component: () => import('../views/consultations/ConsultationHistoryView.vue')
        },
        {
          path: 'administracion/usuarios',
          name: 'admin-usuarios',
          component: () => import('../views/admin/UsersAdminView.vue')
        },
        {
          path: 'administracion/medicos',
          name: 'admin-medicos',
          component: () => import('../views/admin/MedicsAdminView.vue')
        }
      ]
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/login'
    }
  ]
})

router.beforeEach((to, _from, next) => {
  const { isAuthenticated } = useSession()

  if (to.meta.requiresAuth && !isAuthenticated.value) {
    next({ name: 'login' })
    return
  }

  if (to.name === 'login' && isAuthenticated.value) {
    next({ name: 'dashboard' })
    return
  }

  next()
})

export default router
