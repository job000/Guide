#!/bin/bash

# =============================================================================
# NEXT.JS PROSJEKT SETUP SCRIPT
# Kjør: ./setup-project.sh prosjektnavn
# =============================================================================

set -e  # Stopp ved feil

# Farger for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Sjekk at prosjektnavn er gitt
if [ -z "$1" ]; then
    echo -e "${RED}FEIL: Du må oppgi et prosjektnavn${NC}"
    echo "Bruk: ./setup-project.sh prosjektnavn"
    exit 1
fi

PROJECT_NAME=$1

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   OPPRETTER NEXT.JS PROSJEKT: $PROJECT_NAME${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Steg 1: Opprett Next.js prosjekt
echo -e "${YELLOW}[1/6] Oppretter Next.js prosjekt...${NC}"
npx create-next-app@latest "$PROJECT_NAME" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --import-alias "@/*" \
    --turbopack \
    --yes

cd "$PROJECT_NAME"

# Steg 2: Installer avhengigheter
echo -e "${YELLOW}[2/6] Installerer ekstra pakker...${NC}"
npm install @supabase/supabase-js zustand react-hot-toast zod bcryptjs jose
npm install -D @types/bcryptjs

# Steg 3: Opprett mappestruktur
echo -e "${YELLOW}[3/6] Oppretter mappestruktur...${NC}"
mkdir -p src/actions
mkdir -p src/components/layout
mkdir -p src/components/ui
mkdir -p src/components/functional
mkdir -p src/config
mkdir -p src/interfaces
mkdir -p src/lib
mkdir -p src/store
mkdir -p src/hooks

# Steg 4: Opprett konfigurasjonsfiler
echo -e "${YELLOW}[4/6] Oppretter konfigurasjonsfiler...${NC}"

# .env.local
cat > .env.local << 'EOF'
# ===========================================
# SUPABASE KONFIGURASJON
# Hent disse fra: supabase.com -> Settings -> API
# ===========================================
SUPABASE_PROJECT_URL=https://DIN-PROSJEKT-ID.supabase.co
SUPABASE_API_KEY=din-anon-public-key-her

# ===========================================
# JWT FOR AUTENTISERING
# Lag en tilfeldig streng på minst 32 tegn
# ===========================================
JWT_SECRET=EnVeldigLangOgHemmeligNoekkelSomErMinstTrettiToTegn

# ===========================================
# NETTSIDE INFO (for metadata)
# ===========================================
NEXT_PUBLIC_SITE_URL=http://localhost:3000
NEXT_PUBLIC_SITE_NAME=Min Nettside
EOF

# Supabase config
cat > src/config/supabase-config.ts << 'EOF'
import { createClient } from "@supabase/supabase-js"

// Henter miljøvariabler
const supabaseUrl = process.env.SUPABASE_PROJECT_URL!
const supabaseKey = process.env.SUPABASE_API_KEY!

// Oppretter og eksporterer Supabase-klienten
const supabase = createClient(supabaseUrl, supabaseKey)

export default supabase
EOF

# Interfaces
cat > src/interfaces/index.ts << 'EOF'
// ===========================================
// FELLES INTERFACES (Typer)
// Tenk på dette som "klasser" i OOP - de definerer strukturen
// ===========================================

// Standard API-respons - brukes av alle server actions
export interface IApiResponse<T = undefined> {
  success: boolean        // Gikk det bra?
  message?: string        // Melding til bruker
  data?: T               // Eventuell data som returneres
}

// Bruker-type
export interface IUser {
  id: number
  name: string
  email: string
  phone?: string          // ? betyr valgfritt felt
  role: "user" | "admin"  // Kan bare være "user" eller "admin"
  created_at: string
}

// Kontaktskjema-melding
export interface IContactMessage {
  id: number
  name: string
  email: string
  phone?: string
  message: string
  is_read: boolean
  created_at: string
}
EOF

# Utils
cat > src/lib/utils.ts << 'EOF'
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

// Hjelpefunksjon for å kombinere Tailwind-klasser
// Brukes slik: className={cn("text-red-500", isActive && "font-bold")}
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

# Steg 5: Opprett komponenter
echo -e "${YELLOW}[5/6] Oppretter komponenter...${NC}"

# Button komponent
cat > src/components/ui/button.tsx << 'EOF'
// ===========================================
// GJENBRUKBAR KNAPP-KOMPONENT
// Bruk: <Button variant="primary">Klikk meg</Button>
// ===========================================

interface ButtonProps {
  children: React.ReactNode          // Teksten/innholdet i knappen
  variant?: "primary" | "secondary" | "outline"  // Styling-variant
  size?: "sm" | "md" | "lg"          // Størrelse
  disabled?: boolean                  // Deaktivert?
  type?: "button" | "submit"          // HTML type
  onClick?: () => void                // Hva skjer ved klikk
  className?: string                  // Ekstra CSS-klasser
}

export default function Button({
  children,
  variant = "primary",
  size = "md",
  disabled = false,
  type = "button",
  onClick,
  className = "",
}: ButtonProps) {
  // Basis-styling som alle knapper har
  const baseStyles = "rounded-lg font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"

  // Variant-spesifikk styling
  const variantStyles = {
    primary: "bg-blue-600 text-white hover:bg-blue-700 shadow-md hover:shadow-lg",
    secondary: "bg-gray-600 text-white hover:bg-gray-700",
    outline: "border-2 border-blue-600 text-blue-600 hover:bg-blue-50",
  }

  // Størrelse-styling
  const sizeStyles = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-5 py-2.5 text-base",
    lg: "px-7 py-3.5 text-lg",
  }

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]} ${className}`}
    >
      {children}
    </button>
  )
}
EOF

# Input komponent
cat > src/components/ui/input.tsx << 'EOF'
// ===========================================
// GJENBRUKBAR INPUT-KOMPONENT
// Bruk: <Input label="E-post" type="email" name="email" />
// ===========================================

interface InputProps {
  label: string                       // Label-tekst over feltet
  type?: "text" | "email" | "password" | "tel" | "number"
  name: string                        // Feltets navn (for skjema)
  placeholder?: string                // Placeholder-tekst
  required?: boolean                  // Påkrevd felt?
  disabled?: boolean                  // Deaktivert?
  value?: string                      // Kontrollert verdi
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void
  error?: string                      // Feilmelding
  className?: string
}

export default function Input({
  label,
  type = "text",
  name,
  placeholder,
  required = false,
  disabled = false,
  value,
  onChange,
  error,
  className = "",
}: InputProps) {
  return (
    <div className={`mb-4 ${className}`}>
      {/* Label */}
      <label
        htmlFor={name}
        className="block text-sm font-medium text-gray-700 mb-1"
      >
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>

      {/* Input-felt */}
      <input
        type={type}
        id={name}
        name={name}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        value={value}
        onChange={onChange}
        className={`
          w-full px-4 py-2.5
          border rounded-lg
          focus:ring-2 focus:ring-blue-500 focus:border-blue-500
          disabled:bg-gray-100 disabled:cursor-not-allowed
          transition-all duration-200
          ${error ? "border-red-500" : "border-gray-300"}
        `}
      />

      {/* Feilmelding */}
      {error && (
        <p className="mt-1 text-sm text-red-500">{error}</p>
      )}
    </div>
  )
}
EOF

# Header komponent
cat > src/components/layout/header.tsx << 'EOF'
// ===========================================
// HEADER/NAVIGASJON KOMPONENT
// Dette vises øverst på alle sider
// ===========================================
"use client"

import { useState } from "react"
import Link from "next/link"

export default function Header() {
  // State for mobil-meny (åpen/lukket)
  const [isMenuOpen, setIsMenuOpen] = useState(false)

  // Navigasjonslenker - ENDRE DISSE til kundens sider
  const navLinks = [
    { href: "/", label: "Hjem" },
    { href: "/tjenester", label: "Tjenester" },
    { href: "/om-oss", label: "Om oss" },
    { href: "/kontakt", label: "Kontakt" },
  ]

  return (
    <header className="bg-white shadow-sm sticky top-0 z-50">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">

          {/* Logo - ENDRE til kundens logo/navn */}
          <Link href="/" className="flex items-center">
            <span className="text-2xl font-bold text-blue-600">
              Logo Her
            </span>
          </Link>

          {/* Desktop navigasjon */}
          <div className="hidden md:flex items-center space-x-8">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="text-gray-600 hover:text-blue-600 font-medium transition-colors"
              >
                {link.label}
              </Link>
            ))}

            {/* CTA-knapp */}
            <Link
              href="/kontakt"
              className="bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Kontakt oss
            </Link>
          </div>

          {/* Mobil hamburger-knapp */}
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="md:hidden p-2"
            aria-label="Åpne meny"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              {isMenuOpen ? (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              ) : (
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobil meny */}
        {isMenuOpen && (
          <div className="md:hidden py-4 border-t">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className="block py-2 text-gray-600 hover:text-blue-600"
                onClick={() => setIsMenuOpen(false)}
              >
                {link.label}
              </Link>
            ))}
          </div>
        )}
      </nav>
    </header>
  )
}
EOF

# Footer komponent
cat > src/components/layout/footer.tsx << 'EOF'
// ===========================================
// FOOTER KOMPONENT
// Vises nederst på alle sider
// ===========================================

import Link from "next/link"

export default function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">

          {/* Kolonne 1: Om bedriften */}
          <div>
            <h3 className="text-white text-lg font-bold mb-4">Firmanavn</h3>
            <p className="text-sm">
              En kort beskrivelse av bedriften og hva dere gjør.
            </p>
          </div>

          {/* Kolonne 2: Lenker */}
          <div>
            <h3 className="text-white text-lg font-bold mb-4">Snarveier</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/" className="hover:text-white transition-colors">Hjem</Link></li>
              <li><Link href="/tjenester" className="hover:text-white transition-colors">Tjenester</Link></li>
              <li><Link href="/om-oss" className="hover:text-white transition-colors">Om oss</Link></li>
              <li><Link href="/kontakt" className="hover:text-white transition-colors">Kontakt</Link></li>
            </ul>
          </div>

          {/* Kolonne 3: Kontaktinfo */}
          <div>
            <h3 className="text-white text-lg font-bold mb-4">Kontakt</h3>
            <ul className="space-y-2 text-sm">
              <li>Gateadresse 123</li>
              <li>0000 Poststed</li>
              <li>Tlf: 123 45 678</li>
              <li>post@firma.no</li>
            </ul>
          </div>

          {/* Kolonne 4: Åpningstider */}
          <div>
            <h3 className="text-white text-lg font-bold mb-4">Åpningstider</h3>
            <ul className="space-y-2 text-sm">
              <li>Man-Fre: 09:00 - 17:00</li>
              <li>Lør: 10:00 - 15:00</li>
              <li>Søn: Stengt</li>
            </ul>
          </div>
        </div>

        {/* Copyright */}
        <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm">
          <p>&copy; {currentYear} Firmanavn. Alle rettigheter reservert.</p>
        </div>
      </div>
    </footer>
  )
}
EOF

# Kontaktskjema komponent
cat > src/components/functional/contact-form.tsx << 'EOF'
// ===========================================
// KONTAKTSKJEMA KOMPONENT
// Håndterer innsending til database
// ===========================================
"use client"

import { useState } from "react"
import { submitContactForm } from "@/actions/contact"
import Button from "@/components/ui/button"
import Input from "@/components/ui/input"
import toast from "react-hot-toast"

export default function ContactForm() {
  // Loading-state mens skjema sendes
  const [isLoading, setIsLoading] = useState(false)

  // Håndter skjema-innsending
  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()  // Hindre standard form-oppførsel
    setIsLoading(true)

    // Hent data fra skjema
    const formData = new FormData(event.currentTarget)

    // Kall server action
    const result = await submitContactForm(formData)

    if (result.success) {
      toast.success(result.message || "Melding sendt!")
      // Nullstill skjema
      ;(event.target as HTMLFormElement).reset()
    } else {
      toast.error(result.message || "Noe gikk galt")
    }

    setIsLoading(false)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        label="Navn"
        name="name"
        placeholder="Ditt navn"
        required
      />

      <Input
        label="E-post"
        type="email"
        name="email"
        placeholder="din@epost.no"
        required
      />

      <Input
        label="Telefon"
        type="tel"
        name="phone"
        placeholder="12345678"
      />

      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Melding <span className="text-red-500">*</span>
        </label>
        <textarea
          name="message"
          rows={5}
          required
          placeholder="Skriv din melding her..."
          className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200"
        />
      </div>

      <Button type="submit" disabled={isLoading} className="w-full">
        {isLoading ? "Sender..." : "Send melding"}
      </Button>
    </form>
  )
}
EOF

# Contact action
cat > src/actions/contact.ts << 'EOF'
// ===========================================
// SERVER ACTION: KONTAKTSKJEMA
// Kjører på serveren - trygt for database-kall
// ===========================================
"use server"

import supabase from "@/config/supabase-config"
import { IApiResponse } from "@/interfaces"

export async function submitContactForm(formData: FormData): Promise<IApiResponse> {
  try {
    // Hent data fra skjema
    const name = formData.get("name") as string
    const email = formData.get("email") as string
    const phone = formData.get("phone") as string
    const message = formData.get("message") as string

    // Enkel validering
    if (!name || !email || !message) {
      return {
        success: false,
        message: "Vennligst fyll ut alle påkrevde felt",
      }
    }

    // Lagre i database
    const { error } = await supabase
      .from("contact_messages")
      .insert({
        name,
        email,
        phone: phone || null,
        message,
      })

    if (error) {
      console.error("Supabase error:", error)
      return {
        success: false,
        message: "Kunne ikke sende melding. Prøv igjen senere.",
      }
    }

    return {
      success: true,
      message: "Takk for din henvendelse! Vi tar kontakt snart.",
    }
  } catch (error) {
    console.error("Contact form error:", error)
    return {
      success: false,
      message: "En feil oppstod. Prøv igjen senere.",
    }
  }
}
EOF

# Oppdater layout.tsx
cat > src/app/layout.tsx << 'EOF'
// ===========================================
// HOVEDLAYOUT - Wrapper for alle sider
// Header og Footer vises på ALLE sider
// ===========================================

import type { Metadata } from "next"
import { Inter } from "next/font/google"
import { Toaster } from "react-hot-toast"
import Header from "@/components/layout/header"
import Footer from "@/components/layout/footer"
import "./globals.css"

const inter = Inter({ subsets: ["latin"] })

// ENDRE DISSE til kundens info
export const metadata: Metadata = {
  title: "Firmanavn - Kort beskrivelse",
  description: "En beskrivelse av hva bedriften gjør. Viktig for Google-søk.",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="no">
      <body className={inter.className}>
        {/* Toast-meldinger (suksess/feil-varsler) */}
        <Toaster position="top-center" />

        {/* Header vises på alle sider */}
        <Header />

        {/* Hovedinnhold - ulikt per side */}
        <main className="min-h-screen">
          {children}
        </main>

        {/* Footer vises på alle sider */}
        <Footer />
      </body>
    </html>
  )
}
EOF

# Oppdater page.tsx (forside)
cat > src/app/page.tsx << 'EOF'
// ===========================================
// FORSIDE (page.tsx i app/ = forsiden)
// ===========================================

import Link from "next/link"
import Button from "@/components/ui/button"

export default function HomePage() {
  return (
    <div>
      {/* HERO-SEKSJON - Det første besøkende ser */}
      <section className="bg-gradient-to-br from-blue-600 to-blue-800 text-white py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h1 className="text-4xl md:text-6xl font-bold mb-6">
            Velkommen til Firmanavn
          </h1>
          <p className="text-xl md:text-2xl mb-8 text-blue-100 max-w-3xl mx-auto">
            En kort og fengende beskrivelse av hva dere tilbyr og hvorfor kunden bør velge dere.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/kontakt">
              <Button size="lg">Kontakt oss</Button>
            </Link>
            <Link href="/tjenester">
              <Button variant="outline" size="lg" className="border-white text-white hover:bg-white/10">
                Se våre tjenester
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* TJENESTER/FORDELER SEKSJON */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl font-bold text-center mb-12">
            Hvorfor velge oss?
          </h2>

          <div className="grid md:grid-cols-3 gap-8">
            {/* Fordel 1 */}
            <div className="bg-white p-8 rounded-xl shadow-md text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">🎯</span>
              </div>
              <h3 className="text-xl font-bold mb-3">Fordel 1</h3>
              <p className="text-gray-600">
                Beskriv den første fordelen med å velge deres tjenester.
              </p>
            </div>

            {/* Fordel 2 */}
            <div className="bg-white p-8 rounded-xl shadow-md text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">⚡</span>
              </div>
              <h3 className="text-xl font-bold mb-3">Fordel 2</h3>
              <p className="text-gray-600">
                Beskriv den andre fordelen med å velge deres tjenester.
              </p>
            </div>

            {/* Fordel 3 */}
            <div className="bg-white p-8 rounded-xl shadow-md text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">💎</span>
              </div>
              <h3 className="text-xl font-bold mb-3">Fordel 3</h3>
              <p className="text-gray-600">
                Beskriv den tredje fordelen med å velge deres tjenester.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA-SEKSJON (Call to Action) */}
      <section className="py-20 bg-blue-600 text-white">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">
            Klar for å komme i gang?
          </h2>
          <p className="text-xl mb-8 text-blue-100">
            Ta kontakt med oss i dag for en uforpliktende samtale.
          </p>
          <Link href="/kontakt">
            <Button size="lg" variant="outline" className="border-white text-white hover:bg-white hover:text-blue-600">
              Ta kontakt nå
            </Button>
          </Link>
        </div>
      </section>
    </div>
  )
}
EOF

# Kontaktside
mkdir -p src/app/kontakt
cat > src/app/kontakt/page.tsx << 'EOF'
// ===========================================
// KONTAKTSIDE
// ===========================================

import ContactForm from "@/components/functional/contact-form"

export default function KontaktPage() {
  return (
    <div className="py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">Kontakt oss</h1>
          <p className="text-xl text-gray-600">
            Vi hører gjerne fra deg! Fyll ut skjemaet så tar vi kontakt.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-12">
          {/* Kontaktskjema */}
          <div className="bg-white p-8 rounded-xl shadow-lg">
            <h2 className="text-2xl font-bold mb-6">Send oss en melding</h2>
            <ContactForm />
          </div>

          {/* Kontaktinfo */}
          <div>
            <h2 className="text-2xl font-bold mb-6">Kontaktinformasjon</h2>

            <div className="space-y-6">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">📍</span>
                </div>
                <div>
                  <h3 className="font-bold">Adresse</h3>
                  <p className="text-gray-600">Gateadresse 123<br />0000 Poststed</p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">📞</span>
                </div>
                <div>
                  <h3 className="font-bold">Telefon</h3>
                  <p className="text-gray-600">123 45 678</p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">✉️</span>
                </div>
                <div>
                  <h3 className="font-bold">E-post</h3>
                  <p className="text-gray-600">post@firma.no</p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                  <span className="text-2xl">🕐</span>
                </div>
                <div>
                  <h3 className="font-bold">Åpningstider</h3>
                  <p className="text-gray-600">
                    Man-Fre: 09:00 - 17:00<br />
                    Lør: 10:00 - 15:00<br />
                    Søn: Stengt
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Tjenester-side
mkdir -p src/app/tjenester
cat > src/app/tjenester/page.tsx << 'EOF'
// ===========================================
// TJENESTER-SIDE
// ===========================================

export default function TjenesterPage() {
  // ENDRE DENNE listen til kundens tjenester
  const tjenester = [
    {
      title: "Tjeneste 1",
      description: "Beskriv hva denne tjenesten innebærer og hvilke fordeler kunden får.",
      icon: "🎯",
    },
    {
      title: "Tjeneste 2",
      description: "Beskriv hva denne tjenesten innebærer og hvilke fordeler kunden får.",
      icon: "⚡",
    },
    {
      title: "Tjeneste 3",
      description: "Beskriv hva denne tjenesten innebærer og hvilke fordeler kunden får.",
      icon: "💎",
    },
    {
      title: "Tjeneste 4",
      description: "Beskriv hva denne tjenesten innebærer og hvilke fordeler kunden får.",
      icon: "🚀",
    },
  ]

  return (
    <div className="py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">Våre tjenester</h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Vi tilbyr et bredt spekter av tjenester for å hjelpe deg med å nå dine mål.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8">
          {tjenester.map((tjeneste, index) => (
            <div
              key={index}
              className="bg-white p-8 rounded-xl shadow-md hover:shadow-lg transition-shadow"
            >
              <div className="w-16 h-16 bg-blue-100 rounded-xl flex items-center justify-center mb-4">
                <span className="text-3xl">{tjeneste.icon}</span>
              </div>
              <h3 className="text-2xl font-bold mb-3">{tjeneste.title}</h3>
              <p className="text-gray-600">{tjeneste.description}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
EOF

# Om oss-side
mkdir -p src/app/om-oss
cat > src/app/om-oss/page.tsx << 'EOF'
// ===========================================
// OM OSS-SIDE
// ===========================================

export default function OmOssPage() {
  return (
    <div className="py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold mb-4">Om oss</h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Bli bedre kjent med oss og vår historie.
          </p>
        </div>

        {/* Hovedinnhold */}
        <div className="grid md:grid-cols-2 gap-12 items-center mb-16">
          <div>
            <h2 className="text-3xl font-bold mb-4">Vår historie</h2>
            <p className="text-gray-600 mb-4">
              Her kan du skrive om bedriftens historie, når den ble grunnlagt,
              og hva som motiverte starten.
            </p>
            <p className="text-gray-600 mb-4">
              Beskriv reisen fra oppstart til i dag, og hvilke milepæler
              dere har oppnådd underveis.
            </p>
            <p className="text-gray-600">
              Del visjonen deres for fremtiden og hva dere jobber mot.
            </p>
          </div>
          <div className="bg-gray-200 rounded-xl h-80 flex items-center justify-center">
            <span className="text-gray-500">Bilde av teamet/kontoret</span>
          </div>
        </div>

        {/* Verdier */}
        <div className="mb-16">
          <h2 className="text-3xl font-bold text-center mb-8">Våre verdier</h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">🤝</span>
              </div>
              <h3 className="text-xl font-bold mb-2">Tillit</h3>
              <p className="text-gray-600">Beskriv denne verdien</p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">💡</span>
              </div>
              <h3 className="text-xl font-bold mb-2">Innovasjon</h3>
              <p className="text-gray-600">Beskriv denne verdien</p>
            </div>
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-3xl">⭐</span>
              </div>
              <h3 className="text-xl font-bold mb-2">Kvalitet</h3>
              <p className="text-gray-600">Beskriv denne verdien</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
EOF

# Installer clsx og tailwind-merge (trengs for cn())
npm install clsx tailwind-merge

# Steg 6: Ferdig!
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   PROSJEKTET ER KLART!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Neste steg:"
echo -e "  1. ${YELLOW}cd $PROJECT_NAME${NC}"
echo -e "  2. Rediger ${YELLOW}.env.local${NC} med dine Supabase-nøkler"
echo -e "  3. Kjør ${YELLOW}npm run dev${NC}"
echo -e "  4. Åpne ${BLUE}http://localhost:3000${NC}"
echo ""
echo -e "${GREEN}Lykke til!${NC}"
