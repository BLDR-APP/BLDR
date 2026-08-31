import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authorization = req.headers.get('Authorization')
    if (!authorization) return json({ error: 'Não autorizado' }, 401)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )
    const { data: { user }, error } = await supabase.auth.getUser(
      authorization.replace('Bearer ', ''),
    )
    if (error || !user) return json({ error: 'Token inválido' }, 401)

    const activitiesUrl = Deno.env.get('GARMIN_ACTIVITIES_URL')
    if (!activitiesUrl) {
      return json({ error: 'Integração Garmin ainda não configurada' }, 503)
    }
    const { data: token } = await supabase.schema('bldr_club')
      .from('garmin_tokens').select('access_token')
      .eq('user_id', user.id).maybeSingle()
    if (!token) return json({ error: 'Garmin não conectado' }, 404)

    const response = await fetch(activitiesUrl, {
      headers: { Authorization: `Bearer ${token.access_token}` },
    })
    if (!response.ok) return json({ error: 'Falha ao consultar Garmin' }, 502)
    return json({ activities: await response.json() })
  } catch (error) {
    console.error('garmin-activities:', error)
    return json({ error: 'Erro inesperado ao consultar Garmin' }, 500)
  }
})

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status, headers: { 'Content-Type': 'application/json' },
  })
}
