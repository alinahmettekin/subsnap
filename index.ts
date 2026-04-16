import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (_req) => {
    try {
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL')!,
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        )

        const today = new Date()
        today.setHours(0, 0, 0, 0)
        const day1 = new Date(today); day1.setDate(day1.getDate() + 1)
        const day3 = new Date(today); day3.setDate(day3.getDate() + 3)
        const fmt = (d: Date) => d.toISOString().split('T')[0]

        const { data: subs, error: subErr } = await supabase
            .from('subscriptions')
            .select('name, amount, currency, next_payment_date, user_id, cards(card_name, last_four)')
            .eq('status', 'active')
            .eq('reminders_enabled', true)
            .in('next_payment_date', [fmt(day1), fmt(day3)])

        if (subErr) throw new Error(`DB: ${subErr.message}`)
        if (!subs?.length) {
            return new Response(JSON.stringify({ ok: true, message: 'No reminders today' }), {
                headers: { 'Content-Type': 'application/json' }
            })
        }

        const userIds = [...new Set(subs.map((s: any) => s.user_id))]
        const { data: profiles } = await supabase
            .from('profiles')
            .select('id, fcm_token')
            .in('id', userIds)
            .not('fcm_token', 'is', null)
            .eq('notifications_enabled', true)

        const tokenMap = Object.fromEntries(
            (profiles ?? []).map((p: any) => [p.id, p.fcm_token])
        )

        const accessToken = await getGoogleAccessToken(Deno.env.get('FCM_CLIENT_EMAIL')!)
        const projectId = Deno.env.get('FCM_PROJECT_ID')!
        const results = []

        for (const sub of subs) {
            const fcmToken = tokenMap[(sub as any).user_id]
            if (!fcmToken) continue

            const diffDays = Math.round(
                (new Date((sub as any).next_payment_date).getTime() - today.getTime()) / 86400000
            )

            const cardInfo = (sub as any).cards 
                ? `\nSonu ${(sub as any).cards.last_four} olan ${(sub as any).cards.card_name} kartınızın bakiyesini kontrol etmeyi unutmayın.`
                : '\nÖdeme günü bakiyenizi kontrol etmeyi unutmayın!';

            const res = await fetch(
                `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
                {
                    method: 'POST',
                    headers: {
                        Authorization: `Bearer ${accessToken}`,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: {
                            token: fcmToken,
                            notification: {
                                title: 'Ödeme Hatırlatıcısı 💳',
                                body: `${(sub as any).name} ödemesine ${diffDays} gün kaldı! ${(sub as any).amount} ${(sub as any).currency}.${cardInfo}`,
                            },
                        },
                    }),
                }
            )
            const json = await res.json()
            results.push({ name: (sub as any).name, days: diffDays, fcm: json })
        }

        return new Response(JSON.stringify({ ok: true, results }), {
            headers: { 'Content-Type': 'application/json' }
        })
    } catch (e: any) {
        return new Response(JSON.stringify({ error: e.message }), {
            status: 500, headers: { 'Content-Type': 'application/json' }
        })
    }
})

async function getGoogleAccessToken(clientEmail: string): Promise<string> {
    const now = Math.floor(Date.now() / 1000)

    const header = { alg: 'RS256', typ: 'JWT' }
    const payload = {
        iss: clientEmail,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
    }

    const toB64Url = (obj: object) =>
        btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

    const signingInput = `${toB64Url(header)}.${toB64Url(payload)}`

    // FCM_KEY_BODY: PEM'in sadece base64 içeriği (header/footer yok, newline yok)
    const keyBody = Deno.env.get('FCM_KEY_BODY')!
    const keyData = Uint8Array.from(atob(keyBody), c => c.charCodeAt(0))

    const cryptoKey = await crypto.subtle.importKey(
        'pkcs8',
        keyData,
        { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
        false,
        ['sign']
    )

    const signature = await crypto.subtle.sign(
        'RSASSA-PKCS1-v1_5',
        cryptoKey,
        new TextEncoder().encode(signingInput)
    )

    const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

    const jwt = `${signingInput}.${sigB64}`

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt,
        }),
    })

    const data = await tokenRes.json()
    if (!data.access_token) throw new Error(`Token error: ${JSON.stringify(data)}`)
    return data.access_token
}
