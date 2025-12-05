#!/bin/bash

# ============================================================
# Obligar Consulting - Treningssenter/Gym Setup Script
# https://obligarconsulting.no
# ============================================================

set -e

PROJECT_NAME=${1:-"treningssenter-nettside"}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Obligar Consulting - Treningssenter Setup            ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Kjør basis-setup først
curl -fsSL https://obligarconsulting.no/setup.sh | bash -s "$PROJECT_NAME"

cd "$PROJECT_NAME"

echo "Oppretter treningssenter-spesifikke filer..."

# Gym-interfaces
cat >> src/interfaces/index.ts << 'EOF'

// Treningssenter-spesifikke interfaces
export interface IMembership {
  id: number
  name: string
  description: string
  price_monthly: number
  price_yearly: number
  features: string[]
  is_popular: boolean
  sort_order: number
}

export interface IClass {
  id: number
  name: string
  description: string
  instructor: string
  day: string
  start_time: string
  end_time: string
  max_participants: number
  current_participants: number
  difficulty: 'beginner' | 'intermediate' | 'advanced'
}

export interface IClassBooking {
  id: number
  class_id: number
  user_id: number
  status: 'confirmed' | 'cancelled' | 'waitlist'
  created_at: string
}

export interface ITrialSignup {
  id: number
  name: string
  email: string
  phone: string
  preferred_time: string
  experience: string
  goals: string
  status: 'pending' | 'contacted' | 'converted'
  created_at: string
}
EOF

# Gym actions
cat > src/actions/memberships.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"

export async function getMemberships() {
  try {
    const { data, error } = await supabase
      .from("memberships")
      .select("*")
      .order("sort_order")

    if (error) throw error

    return { success: true, data }
  } catch {
    return { success: false, data: [] }
  }
}
EOF

cat > src/actions/classes.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"

export async function getClasses(day?: string) {
  try {
    let query = supabase
      .from("classes")
      .select("*")
      .order("start_time")

    if (day) {
      query = query.eq("day", day)
    }

    const { data, error } = await query

    if (error) throw error

    return { success: true, data }
  } catch {
    return { success: false, data: [] }
  }
}

export async function bookClass(classId: number, userId: number) {
  try {
    const { error } = await supabase
      .from("class_bookings")
      .insert({ class_id: classId, user_id: userId, status: "confirmed" })

    if (error) throw error

    return { success: true, message: "Påmeldt!" }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Kunne ikke melde på"
    return { success: false, message }
  }
}
EOF

cat > src/actions/trial.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"

export async function submitTrialSignup(payload: {
  name: string
  email: string
  phone: string
  preferred_time: string
  experience: string
  goals: string
}) {
  try {
    const { error } = await supabase
      .from("trial_signups")
      .insert({ ...payload, status: "pending" })

    if (error) throw error

    return { success: true, message: "Takk! Vi kontakter deg for å avtale prøvetime." }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Kunne ikke registrere"
    return { success: false, message }
  }
}
EOF

# Gym forside
cat > src/app/page.tsx << 'EOF'
import Link from "next/link"
import { getMemberships } from "@/actions/memberships"
import { Check } from "lucide-react"

export default async function HomePage() {
  const { data: memberships } = await getMemberships()

  return (
    <>
      {/* Hero */}
      <section className="relative h-[80vh] bg-gradient-to-br from-gray-900 via-gray-800 to-black text-white flex items-center">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h1 className="text-5xl md:text-7xl font-black mb-6 tracking-tight">
            TRENINGSSENTER
          </h1>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Moderne treningssenter med førsteklasses utstyr og personlig oppfølging
          </p>
          <div className="flex gap-4 justify-center flex-wrap">
            <Link
              href="/prov-gratis"
              className="bg-green-500 text-white px-8 py-4 rounded-md font-bold text-lg hover:bg-green-600 transition-colors"
            >
              PRØV GRATIS
            </Link>
            <Link
              href="/medlemskap"
              className="border-2 border-white text-white px-8 py-4 rounded-md font-bold text-lg hover:bg-white/10 transition-colors"
            >
              SE PRISER
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-gray-100">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">Våre fasiliteter</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {[
              { title: "Styrkerom", desc: "500m² med frivekter og maskiner" },
              { title: "Gruppetimer", desc: "Spinning, yoga, HIIT og mer" },
              { title: "PT-sone", desc: "Personlig trener-opplegg" },
              { title: "Garderober", desc: "Badstue, dusj, låsbare skap" },
            ].map((item, i) => (
              <div key={i} className="bg-white p-6 rounded-lg shadow-lg text-center">
                <div className="w-16 h-16 bg-green-500 rounded-full mx-auto mb-4 flex items-center justify-center text-white font-bold text-2xl">
                  {i + 1}
                </div>
                <h3 className="font-bold mb-2">{item.title}</h3>
                <p className="text-gray-600 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="py-20">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-4">Medlemskap</h2>
          <p className="text-center text-gray-600 mb-12">Ingen binding - avslutt når du vil</p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {memberships?.map((plan) => (
              <div
                key={plan.id}
                className={`rounded-xl p-8 ${plan.is_popular ? 'bg-green-500 text-white scale-105 shadow-xl' : 'bg-white border shadow-lg'}`}
              >
                {plan.is_popular && (
                  <span className="bg-yellow-400 text-black text-xs font-bold px-3 py-1 rounded-full">
                    MEST POPULÆR
                  </span>
                )}
                <h3 className="text-2xl font-bold mt-4">{plan.name}</h3>
                <p className={`text-sm mb-4 ${plan.is_popular ? 'text-green-100' : 'text-gray-600'}`}>
                  {plan.description}
                </p>
                <div className="mb-6">
                  <span className="text-4xl font-black">{plan.price_monthly} kr</span>
                  <span className={plan.is_popular ? 'text-green-100' : 'text-gray-500'}>/mnd</span>
                </div>
                <ul className="space-y-3 mb-8">
                  {plan.features?.map((feature, i) => (
                    <li key={i} className="flex items-center gap-2">
                      <Check className={`w-5 h-5 ${plan.is_popular ? 'text-yellow-300' : 'text-green-500'}`} />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
                <Link
                  href="/prov-gratis"
                  className={`block text-center py-3 rounded-md font-bold ${
                    plan.is_popular
                      ? 'bg-white text-green-500 hover:bg-gray-100'
                      : 'bg-green-500 text-white hover:bg-green-600'
                  } transition-colors`}
                >
                  Start i dag
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="bg-gray-900 text-white py-20">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">Klar for å komme i form?</h2>
          <p className="text-gray-400 mb-8">Prøv oss gratis i 7 dager - ingen forpliktelser</p>
          <Link
            href="/prov-gratis"
            className="bg-green-500 text-white px-10 py-4 rounded-md font-bold text-lg hover:bg-green-600 transition-colors inline-block"
          >
            PRØV GRATIS NÅ
          </Link>
        </div>
      </section>
    </>
  )
}
EOF

# Prøv gratis side
mkdir -p src/app/prov-gratis
cat > src/app/prov-gratis/page.tsx << 'EOF'
"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import toast from "react-hot-toast"
import { submitTrialSignup } from "@/actions/trial"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const schema = z.object({
  name: z.string().min(2, "Navn må være minst 2 tegn"),
  email: z.string().email("Ugyldig e-post"),
  phone: z.string().min(8, "Ugyldig telefonnummer"),
  preferred_time: z.string().min(1, "Velg foretrukket tid"),
  experience: z.string().min(1, "Velg erfaring"),
  goals: z.string().min(10, "Fortell oss om dine mål"),
})

type FormData = z.infer<typeof schema>

export default function TrialPage() {
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      const result = await submitTrialSignup(data)
      if (result.success) {
        toast.success(result.message)
        reset()
      } else {
        toast.error(result.message)
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-100 py-20">
      <div className="max-w-xl mx-auto px-4">
        <div className="bg-green-500 text-white text-center py-6 rounded-t-xl">
          <h1 className="text-3xl font-bold">7 DAGER GRATIS</h1>
          <p className="text-green-100">Ingen binding eller forpliktelser</p>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-8 rounded-b-xl shadow-lg space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Fullt navn</label>
            <Input {...register("name")} placeholder="Ola Nordmann" />
            {errors.name && <p className="text-red-500 text-sm">{errors.name.message}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">E-post</label>
              <Input {...register("email")} type="email" placeholder="ola@eksempel.no" />
              {errors.email && <p className="text-red-500 text-sm">{errors.email.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Telefon</label>
              <Input {...register("phone")} type="tel" placeholder="12345678" />
              {errors.phone && <p className="text-red-500 text-sm">{errors.phone.message}</p>}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Foretrukket tid</label>
            <select {...register("preferred_time")} className="w-full px-3 py-2 border rounded-md">
              <option value="">Velg...</option>
              <option value="morning">Morgen (06-10)</option>
              <option value="midday">Midt på dagen (10-14)</option>
              <option value="afternoon">Ettermiddag (14-18)</option>
              <option value="evening">Kveld (18-22)</option>
            </select>
            {errors.preferred_time && <p className="text-red-500 text-sm">{errors.preferred_time.message}</p>}
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Treningserfaring</label>
            <select {...register("experience")} className="w-full px-3 py-2 border rounded-md">
              <option value="">Velg...</option>
              <option value="beginner">Nybegynner</option>
              <option value="some">Noe erfaring</option>
              <option value="experienced">Erfaren</option>
            </select>
            {errors.experience && <p className="text-red-500 text-sm">{errors.experience.message}</p>}
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Hva er dine treningsmål?</label>
            <textarea
              {...register("goals")}
              className="w-full px-3 py-2 border rounded-md"
              rows={3}
              placeholder="F.eks. gå ned i vekt, bygge muskler, bli sterkere..."
            />
            {errors.goals && <p className="text-red-500 text-sm">{errors.goals.message}</p>}
          </div>

          <Button type="submit" className="w-full bg-green-500 hover:bg-green-600 py-3 text-lg font-bold" disabled={loading}>
            {loading ? "Sender..." : "START GRATIS PRØVEPERIODE"}
          </Button>

          <p className="text-center text-sm text-gray-500">
            Vi kontakter deg innen 24 timer for å avtale din første trening
          </p>
        </form>
      </div>
    </div>
  )
}
EOF

# Timeplan side
mkdir -p src/app/timeplan
cat > src/app/timeplan/page.tsx << 'EOF'
import { getClasses } from "@/actions/classes"

const DAYS = ["Mandag", "Tirsdag", "Onsdag", "Torsdag", "Fredag", "Lørdag", "Søndag"]

export default async function SchedulePage() {
  const { data: classes } = await getClasses()

  const classesByDay = DAYS.reduce((acc, day) => {
    acc[day] = classes?.filter(c => c.day === day) || []
    return acc
  }, {} as Record<string, typeof classes>)

  return (
    <div className="py-20">
      <div className="max-w-6xl mx-auto px-4">
        <h1 className="text-3xl font-bold text-center mb-12">Timeplan</h1>

        <div className="grid grid-cols-1 md:grid-cols-7 gap-2">
          {DAYS.map((day) => (
            <div key={day} className="bg-white rounded-lg shadow overflow-hidden">
              <div className="bg-gray-900 text-white py-3 text-center font-bold">
                {day}
              </div>
              <div className="p-2 space-y-2 min-h-[300px]">
                {classesByDay[day]?.map((cls) => (
                  <div
                    key={cls.id}
                    className={`p-2 rounded text-sm ${
                      cls.difficulty === 'beginner' ? 'bg-green-100' :
                      cls.difficulty === 'intermediate' ? 'bg-yellow-100' :
                      'bg-red-100'
                    }`}
                  >
                    <div className="font-semibold">{cls.name}</div>
                    <div className="text-xs text-gray-600">
                      {cls.start_time} - {cls.end_time}
                    </div>
                    <div className="text-xs text-gray-500">{cls.instructor}</div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-8 flex gap-4 justify-center">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-100 rounded"></div>
            <span className="text-sm">Nybegynner</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-yellow-100 rounded"></div>
            <span className="text-sm">Middels</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-100 rounded"></div>
            <span className="text-sm">Avansert</span>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

chmod +x /Users/johnmichael/Downloads/next-job-board-2025-udemy-main/docs/scripts/setup-gym.sh

echo ""
echo "Treningssenter SQL (kjør i Supabase):"
echo ""
cat << 'SQLEOF'
CREATE TABLE memberships (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10, 2) NOT NULL,
  price_yearly DECIMAL(10, 2),
  features TEXT[] DEFAULT '{}',
  is_popular BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0
);

CREATE TABLE classes (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  instructor VARCHAR(255),
  day VARCHAR(50) NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  max_participants INTEGER DEFAULT 20,
  current_participants INTEGER DEFAULT 0,
  difficulty VARCHAR(50) DEFAULT 'intermediate'
);

CREATE TABLE class_bookings (
  id SERIAL PRIMARY KEY,
  class_id INTEGER REFERENCES classes(id),
  user_id INTEGER REFERENCES users(id),
  status VARCHAR(50) DEFAULT 'confirmed',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE trial_signups (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  preferred_time VARCHAR(100),
  experience VARCHAR(100),
  goals TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE trial_signups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON memberships FOR ALL USING (true);
CREATE POLICY "Allow all" ON classes FOR ALL USING (true);
CREATE POLICY "Allow all" ON class_bookings FOR ALL USING (true);
CREATE POLICY "Allow all" ON trial_signups FOR ALL USING (true);

-- Eksempel-data
INSERT INTO memberships (name, description, price_monthly, features, is_popular, sort_order) VALUES
('Basis', 'Tilgang til styrkerom', 299, ARRAY['Styrkerom', 'Garderobe', 'Åpent 06-22'], false, 1),
('Pluss', 'Alt inkludert', 449, ARRAY['Styrkerom', 'Alle gruppetimer', 'Garderobe + badstue', 'Åpent 24/7', 'Gratis PT-time'], true, 2),
('Familie', 'For hele familien', 699, ARRAY['2 voksne + 2 barn', 'Alt fra Pluss', 'Barnepass'], false, 3);

INSERT INTO classes (name, instructor, day, start_time, end_time, difficulty) VALUES
('Spinning', 'Lisa', 'Mandag', '07:00', '08:00', 'intermediate'),
('Yoga', 'Maria', 'Mandag', '18:00', '19:00', 'beginner'),
('HIIT', 'Jonas', 'Tirsdag', '17:00', '17:45', 'advanced'),
('Styrke', 'Erik', 'Onsdag', '12:00', '13:00', 'intermediate');
SQLEOF
echo ""
echo "Treningssenter-prosjekt opprettet!"
