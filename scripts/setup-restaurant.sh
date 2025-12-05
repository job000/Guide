#!/bin/bash

# ============================================================
# Obligar Consulting - Restaurant/Café Setup Script
# https://obligarconsulting.no
# ============================================================

set -e

PROJECT_NAME=${1:-"restaurant-nettside"}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Obligar Consulting - Restaurant/Café Setup           ║"
echo "╚══════════════════════════════════════════════════════════╝"

# Kjør basis-setup først
curl -fsSL https://obligarconsulting.no/setup.sh | bash -s "$PROJECT_NAME"

cd "$PROJECT_NAME"

# Legg til restaurant-spesifikke tabeller
echo "Oppretter restaurant-spesifikke filer..."

# Meny-interface
cat >> src/interfaces/index.ts << 'EOF'

// Restaurant-spesifikke interfaces
export interface IMenuItem {
  id: number
  category: string
  name: string
  description?: string
  price: number
  image_url?: string
  is_vegetarian: boolean
  is_vegan: boolean
  is_available: boolean
  sort_order: number
  created_at: string
}

export interface IReservation {
  id: number
  name: string
  email: string
  phone: string
  date: string
  time: string
  guests: number
  special_requests?: string
  status: 'pending' | 'confirmed' | 'cancelled'
  created_at: string
}

export interface IOpeningHours {
  id: number
  day: string
  open_time: string
  close_time: string
  is_closed: boolean
}
EOF

# Restaurant actions
cat > src/actions/menu.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"

export async function getMenuItems(category?: string) {
  try {
    let query = supabase
      .from("menu_items")
      .select("*")
      .eq("is_available", true)
      .order("sort_order")

    if (category) {
      query = query.eq("category", category)
    }

    const { data, error } = await query

    if (error) throw error

    return { success: true, data }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Kunne ikke hente meny"
    return { success: false, message, data: [] }
  }
}

export async function getCategories() {
  try {
    const { data, error } = await supabase
      .from("menu_items")
      .select("category")
      .eq("is_available", true)

    if (error) throw error

    const categories = [...new Set(data?.map(item => item.category))]
    return { success: true, data: categories }
  } catch {
    return { success: false, data: [] }
  }
}
EOF

cat > src/actions/reservation.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"

export async function createReservation(payload: {
  name: string
  email: string
  phone: string
  date: string
  time: string
  guests: number
  special_requests?: string
}) {
  try {
    const { error } = await supabase
      .from("reservations")
      .insert({ ...payload, status: "pending" })

    if (error) throw error

    return { success: true, message: "Reservasjon mottatt! Vi bekrefter snart." }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Kunne ikke opprette reservasjon"
    return { success: false, message }
  }
}

export async function getReservations() {
  try {
    const { data, error } = await supabase
      .from("reservations")
      .select("*")
      .order("date", { ascending: true })

    if (error) throw error

    return { success: true, data }
  } catch {
    return { success: false, data: [] }
  }
}
EOF

# Restaurant forside
cat > src/app/page.tsx << 'EOF'
import Link from "next/link"
import { getMenuItems } from "@/actions/menu"

export default async function HomePage() {
  const { data: featuredItems } = await getMenuItems()
  const featured = featuredItems?.slice(0, 3) || []

  return (
    <>
      {/* Hero */}
      <section className="relative h-[70vh] bg-gradient-to-r from-amber-900 to-amber-700 text-white flex items-center">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h1 className="text-5xl md:text-6xl font-bold mb-6">
            Restaurantnavn
          </h1>
          <p className="text-xl text-amber-100 mb-8 max-w-2xl mx-auto">
            Autentisk mat i hyggelige omgivelser
          </p>
          <div className="flex gap-4 justify-center flex-wrap">
            <Link
              href="/reserver"
              className="bg-white text-amber-900 px-8 py-3 rounded-md font-medium hover:bg-amber-50 transition-colors"
            >
              Reserver bord
            </Link>
            <Link
              href="/meny"
              className="border-2 border-white text-white px-8 py-3 rounded-md font-medium hover:bg-white/10 transition-colors"
            >
              Se meny
            </Link>
          </div>
        </div>
      </section>

      {/* Featured */}
      <section className="py-20">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">Populære retter</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {featured.map((item) => (
              <div key={item.id} className="bg-white rounded-lg overflow-hidden shadow-lg">
                <div className="h-48 bg-amber-100" />
                <div className="p-6">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-xl font-semibold">{item.name}</h3>
                    <span className="text-amber-600 font-bold">{item.price} kr</span>
                  </div>
                  <p className="text-gray-600">{item.description}</p>
                </div>
              </div>
            ))}
          </div>
          <div className="text-center mt-8">
            <Link href="/meny" className="text-amber-600 font-medium hover:underline">
              Se hele menyen →
            </Link>
          </div>
        </div>
      </section>

      {/* Info */}
      <section className="bg-amber-50 py-20">
        <div className="max-w-6xl mx-auto px-4 grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div>
            <h3 className="text-xl font-semibold mb-2">Åpningstider</h3>
            <p className="text-gray-600">Man-Fre: 11-22</p>
            <p className="text-gray-600">Lør-Søn: 12-23</p>
          </div>
          <div>
            <h3 className="text-xl font-semibold mb-2">Adresse</h3>
            <p className="text-gray-600">Gateadresse 123</p>
            <p className="text-gray-600">0000 By</p>
          </div>
          <div>
            <h3 className="text-xl font-semibold mb-2">Kontakt</h3>
            <p className="text-gray-600">+47 123 45 678</p>
            <p className="text-gray-600">post@restaurant.no</p>
          </div>
        </div>
      </section>
    </>
  )
}
EOF

# Menyside
mkdir -p src/app/meny
cat > src/app/meny/page.tsx << 'EOF'
import { getMenuItems, getCategories } from "@/actions/menu"

export default async function MenuPage() {
  const { data: items } = await getMenuItems()
  const { data: categories } = await getCategories()

  const groupedItems = categories?.reduce((acc, category) => {
    acc[category] = items?.filter(item => item.category === category) || []
    return acc
  }, {} as Record<string, typeof items>)

  return (
    <div className="py-20">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-4xl font-bold text-center mb-12">Vår Meny</h1>

        {categories?.map((category) => (
          <div key={category} className="mb-12">
            <h2 className="text-2xl font-semibold mb-6 text-amber-800 border-b-2 border-amber-200 pb-2">
              {category}
            </h2>
            <div className="space-y-6">
              {groupedItems?.[category]?.map((item) => (
                <div key={item.id} className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="font-semibold">{item.name}</h3>
                      {item.is_vegetarian && <span className="text-xs bg-green-100 text-green-800 px-2 py-0.5 rounded">V</span>}
                      {item.is_vegan && <span className="text-xs bg-green-100 text-green-800 px-2 py-0.5 rounded">Vegan</span>}
                    </div>
                    <p className="text-gray-600 text-sm">{item.description}</p>
                  </div>
                  <span className="text-amber-600 font-bold ml-4">{item.price} kr</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
EOF

# Reservasjonsside
mkdir -p src/app/reserver
cat > src/app/reserver/page.tsx << 'EOF'
"use client"

import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import toast from "react-hot-toast"
import { createReservation } from "@/actions/reservation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

const schema = z.object({
  name: z.string().min(2, "Navn må være minst 2 tegn"),
  email: z.string().email("Ugyldig e-post"),
  phone: z.string().min(8, "Ugyldig telefonnummer"),
  date: z.string().min(1, "Velg dato"),
  time: z.string().min(1, "Velg tidspunkt"),
  guests: z.coerce.number().min(1).max(20),
  special_requests: z.string().optional(),
})

type FormData = z.infer<typeof schema>

export default function ReservationPage() {
  const [loading, setLoading] = useState(false)

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    setLoading(true)
    try {
      const result = await createReservation(data)
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
    <div className="py-20 bg-amber-50 min-h-screen">
      <div className="max-w-xl mx-auto px-4">
        <h1 className="text-3xl font-bold text-center mb-8">Reserver bord</h1>

        <form onSubmit={handleSubmit(onSubmit)} className="bg-white p-8 rounded-lg shadow-lg space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Navn</label>
              <Input {...register("name")} />
              {errors.name && <p className="text-red-500 text-sm">{errors.name.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Telefon</label>
              <Input {...register("phone")} type="tel" />
              {errors.phone && <p className="text-red-500 text-sm">{errors.phone.message}</p>}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">E-post</label>
            <Input {...register("email")} type="email" />
            {errors.email && <p className="text-red-500 text-sm">{errors.email.message}</p>}
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Dato</label>
              <Input {...register("date")} type="date" />
              {errors.date && <p className="text-red-500 text-sm">{errors.date.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Tid</label>
              <Input {...register("time")} type="time" />
              {errors.time && <p className="text-red-500 text-sm">{errors.time.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Antall</label>
              <Input {...register("guests")} type="number" min={1} max={20} defaultValue={2} />
              {errors.guests && <p className="text-red-500 text-sm">{errors.guests.message}</p>}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Spesielle ønsker (valgfritt)</label>
            <textarea
              {...register("special_requests")}
              className="w-full px-3 py-2 border rounded-md"
              rows={3}
              placeholder="Allergier, bursdag, etc."
            />
          </div>

          <Button type="submit" className="w-full bg-amber-600 hover:bg-amber-700" disabled={loading}>
            {loading ? "Sender..." : "Reserver bord"}
          </Button>
        </form>
      </div>
    </div>
  )
}
EOF

echo ""
echo "Restaurant SQL (kjør i Supabase):"
echo ""
cat << 'SQLEOF'
CREATE TABLE menu_items (
  id SERIAL PRIMARY KEY,
  category VARCHAR(100) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image_url VARCHAR(500),
  is_vegetarian BOOLEAN DEFAULT false,
  is_vegan BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE reservations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  time TIME NOT NULL,
  guests INTEGER NOT NULL,
  special_requests TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON menu_items FOR ALL USING (true);
CREATE POLICY "Allow all" ON reservations FOR ALL USING (true);

-- Eksempel-data
INSERT INTO menu_items (category, name, description, price, is_vegetarian) VALUES
('Forrett', 'Bruschetta', 'Med tomater, basilikum og hvitløk', 89, true),
('Forrett', 'Carpaccio', 'Tynnskåret okse med parmesan', 129, false),
('Hovedrett', 'Pasta Carbonara', 'Klassisk italiensk pasta', 189, false),
('Hovedrett', 'Risotto', 'Med sopp og parmesan', 179, true),
('Dessert', 'Tiramisu', 'Hjemmelaget', 99, true);
SQLEOF
echo ""
echo "Restaurant-prosjekt opprettet!"
