export const motivationalPhrases = [
  'Recuerda: cada diagnóstico oportuno transforma una vida.',
  'Tu experiencia es la medicina que más necesitan hoy.',
  'La empatía que brindas sana tanto como cualquier tratamiento.',
  'Una consulta bien documentada es un paso hacia la prevención.',
  'Hoy tienes la oportunidad de marcar una diferencia real.',
  'La constancia en tus registros protege a cada paciente.',
  'Tu dedicación es parte del bienestar de toda la comunidad médica.'
]

export function getRandomPhrase() {
  return motivationalPhrases[Math.floor(Math.random() * motivationalPhrases.length)]
}
