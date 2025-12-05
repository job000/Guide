#!/bin/bash

# ============================================================
# Obligar Consulting - Next.js 16 Prosjekt Setup Script
# https://obligarconsulting.no
# ============================================================
# Bruk: ./setup.sh prosjektnavn
# Eller: curl -fsSL https://obligarconsulting.no/setup.sh | bash -s prosjektnavn
# ============================================================
# Testet på: macOS 14+, Ubuntu 22.04+, Windows (Git Bash/WSL)
# ============================================================

set -e  # Avslutt ved feil
set -o pipefail  # Avslutt hvis pipe feiler

# ============================================================
# FARGER OG HJELPEFUNKSJONER
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funksjon for å skrive ut med farge
print_step() {
  echo -e "${BLUE}▸${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

# Funksjon for å sjekke om kommando finnes
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Funksjon for å sammenligne versjoner
version_gte() {
  printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# ============================================================
# PREREQUISITE SJEKK
# ============================================================
check_prerequisites() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  SJEKKER SYSTEMKRAV${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  local has_errors=false
  local has_warnings=false

  # Sjekk OS
  print_step "Sjekker operativsystem..."
  case "$(uname -s)" in
    Darwin)
      print_success "macOS $(sw_vers -productVersion) oppdaget"
      OS="macos"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_success "Linux ($NAME $VERSION_ID) oppdaget"
      else
        print_success "Linux oppdaget"
      fi
      OS="linux"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      print_success "Windows (Git Bash/MSYS) oppdaget"
      OS="windows"
      ;;
    *)
      print_warning "Ukjent operativsystem: $(uname -s)"
      OS="unknown"
      ;;
  esac

  # Sjekk Node.js
  print_step "Sjekker Node.js..."
  if command_exists node; then
    NODE_VERSION=$(node -v | sed 's/v//')
    if version_gte "$NODE_VERSION" "18.17.0"; then
      print_success "Node.js v$NODE_VERSION (minimum v18.17.0 ✓)"
    else
      print_error "Node.js v$NODE_VERSION er for gammel. Minimum v18.17.0 kreves."
      has_errors=true
    fi
  else
    print_error "Node.js er ikke installert!"
    has_errors=true

    # Gi installasjonsinstruksjoner
    echo ""
    if [ "$OS" = "macos" ]; then
      echo -e "${YELLOW}Installer Node.js på Mac:${NC}"
      echo "  Alternativ 1 (Homebrew): brew install node@20"
      echo "  Alternativ 2 (nvm):      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
      echo "                           nvm install 20"
      echo "  Alternativ 3:            https://nodejs.org/en/download/"
    elif [ "$OS" = "linux" ]; then
      echo -e "${YELLOW}Installer Node.js på Linux:${NC}"
      echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
      echo "  sudo apt-get install -y nodejs"
    else
      echo -e "${YELLOW}Last ned Node.js fra: https://nodejs.org/en/download/${NC}"
    fi
    echo ""
  fi

  # Sjekk npm
  print_step "Sjekker npm..."
  if command_exists npm; then
    NPM_VERSION=$(npm -v)
    if version_gte "$NPM_VERSION" "9.0.0"; then
      print_success "npm v$NPM_VERSION (minimum v9.0.0 ✓)"
    else
      print_warning "npm v$NPM_VERSION. Anbefaler oppdatering: npm install -g npm@latest"
      has_warnings=true
    fi
  else
    print_error "npm er ikke installert!"
    has_errors=true
  fi

  # Sjekk git
  print_step "Sjekker git..."
  if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "git v$GIT_VERSION"
  else
    print_warning "git er ikke installert (valgfritt men anbefalt)"
    has_warnings=true

    if [ "$OS" = "macos" ]; then
      echo -e "  ${YELLOW}Installer: xcode-select --install${NC}"
    fi
  fi

  # Sjekk ledig diskplass (minst 1GB)
  print_step "Sjekker diskplass..."
  if [ "$OS" = "macos" ]; then
    FREE_SPACE_MB=$(df -m . | awk 'NR==2 {print $4}')
  else
    FREE_SPACE_MB=$(df -m . | awk 'NR==2 {print $4}')
  fi

  if [ "$FREE_SPACE_MB" -gt 1024 ]; then
    print_success "Ledig plass: $(echo "scale=1; $FREE_SPACE_MB/1024" | bc 2>/dev/null || echo "$((FREE_SPACE_MB/1024))")GB"
  else
    print_warning "Lite diskplass: ${FREE_SPACE_MB}MB. Anbefaler minst 1GB."
    has_warnings=true
  fi

  # Sjekk internettforbindelse
  print_step "Sjekker internettforbindelse..."
  if curl -s --head --connect-timeout 5 https://registry.npmjs.org > /dev/null 2>&1; then
    print_success "Internettforbindelse OK"
  else
    print_error "Kan ikke nå npm registry. Sjekk internettforbindelsen."
    has_errors=true
  fi

  # Oppsummering
  echo ""
  if [ "$has_errors" = true ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  FEIL FUNNET - Fiks problemene over før du fortsetter${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
  elif [ "$has_warnings" = true ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Advarsler funnet, men kan fortsette${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "Vil du fortsette likevel? (j/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
      exit 1
    fi
  else
    print_success "Alle systemkrav oppfylt!"
  fi
  echo ""
}

# ============================================================
# MAIN SCRIPT
# ============================================================

# Prosjektnavn fra argument
PROJECT_NAME=${1:-""}

# Vis hjelp hvis ingen argument
if [ -z "$PROJECT_NAME" ]; then
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗"
  echo "║     Obligar Consulting - Next.js 16 Project Setup        ║"
  echo "║              https://obligarconsulting.no                ║"
  echo "╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${YELLOW}Bruk:${NC}"
  echo "  ./setup.sh <prosjektnavn>"
  echo ""
  echo -e "${YELLOW}Eksempler:${NC}"
  echo "  ./setup.sh restaurant-webapp"
  echo "  ./setup.sh min-bedrift"
  echo "  ./setup.sh kunde-nettside"
  echo ""
  echo -e "${YELLOW}Tips:${NC}"
  echo "  - Bruk kun små bokstaver, tall og bindestrek"
  echo "  - Unngå mellomrom og spesialtegn"
  echo ""
  exit 0
fi

# Valider prosjektnavn
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  print_error "Ugyldig prosjektnavn: $PROJECT_NAME"
  echo "Prosjektnavn må:"
  echo "  - Starte og slutte med bokstav eller tall"
  echo "  - Kun inneholde små bokstaver, tall eller bindestrek"
  echo "  - Være minst 1 tegn langt"
  exit 1
fi

# Sjekk om mappe allerede finnes
if [ -d "$PROJECT_NAME" ]; then
  print_error "Mappen '$PROJECT_NAME' finnes allerede!"
  echo "Velg et annet navn eller slett mappen først."
  exit 1
fi

# Vis header
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗"
echo "║     Obligar Consulting - Next.js 16 Project Setup        ║"
echo "║              https://obligarconsulting.no                ║"
echo "╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Kjør prerequisite-sjekk
check_prerequisites

echo -e "${GREEN}▸ Oppretter prosjekt: ${PROJECT_NAME}${NC}"
echo ""

# ============================================================
# STEG 1: OPPRETT NEXT.JS PROSJEKT
# ============================================================
echo -e "${YELLOW}[1/7] Oppretter Next.js 16 prosjekt med Turbopack...${NC}"

# Bruk --yes for å unngå interaktive prompts
npx create-next-app@16 "$PROJECT_NAME" \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --turbopack \
  --import-alias "@/*" \
  --yes

cd "$PROJECT_NAME"

print_success "Next.js 16 prosjekt opprettet"

# ============================================================
# STEG 2: INSTALLER AVHENGIGHETER
# ============================================================
echo ""
echo -e "${YELLOW}[2/7] Installerer avhengigheter...${NC}"

# Hovedavhengigheter
npm install \
  @supabase/supabase-js \
  zustand \
  react-hook-form \
  @hookform/resolvers \
  zod \
  bcryptjs \
  jsonwebtoken \
  js-cookie \
  react-hot-toast \
  lucide-react \
  dayjs \
  clsx \
  tailwind-merge \
  class-variance-authority \
  @radix-ui/react-label \
  @radix-ui/react-slot

# Dev-avhengigheter (typer)
npm install -D \
  @types/bcryptjs \
  @types/jsonwebtoken \
  @types/js-cookie

print_success "Alle avhengigheter installert"

# ============================================================
# STEG 3: OPPRETT MAPPESTRUKTUR
# ============================================================
echo ""
echo -e "${YELLOW}[3/7] Oppretter mappestruktur...${NC}"

mkdir -p src/actions
mkdir -p src/components/ui
mkdir -p src/components/layout
mkdir -p src/components/functional
mkdir -p src/config
mkdir -p src/interfaces
mkdir -p src/lib
mkdir -p src/store
mkdir -p src/hooks
mkdir -p src/app/\(public\)
mkdir -p src/app/\(private\)

print_success "Mappestruktur opprettet"

# ============================================================
# STEG 4: OPPRETT KONFIGURASJONSFILER
# ============================================================
echo ""
echo -e "${YELLOW}[4/7] Oppretter konfigurasjonsfiler...${NC}"

# .env.local
cat > .env.local << 'EOF'
# ============================================================
# MILJØVARIABLER - Obligar Consulting
# ============================================================

# Supabase (hent fra supabase.com → Settings → API)
SUPABASE_PROJECT_URL=https://din-id.supabase.co
SUPABASE_API_KEY=din-anon-key

# JWT Secret (minst 32 tegn - generer med: openssl rand -base64 32)
JWT_SECRET=MinstTrettiToTegnLangHemmeligNokkel123456

# E-post (valgfritt - for kontaktskjema)
NODEMAILER_APP_PASSWORD=
EOF

# .env.example (for versjonskontroll)
cat > .env.example << 'EOF'
# Kopier til .env.local og fyll inn verdier
SUPABASE_PROJECT_URL=https://din-id.supabase.co
SUPABASE_API_KEY=din-anon-key
JWT_SECRET=generer-med-openssl-rand-base64-32
NODEMAILER_APP_PASSWORD=
EOF

# Legg til .env.local i .gitignore hvis ikke allerede der
if ! grep -q ".env.local" .gitignore 2>/dev/null; then
  echo ".env.local" >> .gitignore
fi

# Supabase config
cat > src/config/supabase-config.ts << 'EOF'
import { createClient } from "@supabase/supabase-js"

const supabaseUrl = process.env.SUPABASE_PROJECT_URL!
const supabaseKey = process.env.SUPABASE_API_KEY!

if (!supabaseUrl || !supabaseKey) {
  throw new Error("Supabase-konfigurasjon mangler i .env.local")
}

const supabase = createClient(supabaseUrl, supabaseKey)

export default supabase
EOF

# Utils
cat > src/lib/utils.ts << 'EOF'
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Formater dato
export function formatDate(date: string | Date): string {
  return new Date(date).toLocaleDateString("nb-NO", {
    day: "numeric",
    month: "long",
    year: "numeric",
  })
}

// Formater pris (norsk format)
export function formatPrice(amount: number): string {
  return new Intl.NumberFormat("nb-NO", {
    style: "currency",
    currency: "NOK",
    minimumFractionDigits: 0,
  }).format(amount)
}
EOF

# Interfaces
cat > src/interfaces/index.ts << 'EOF'
// ============================================================
// INTERFACES - Obligar Consulting
// ============================================================

// Bruker
export interface IUser {
  id: number
  name: string
  email: string
  role: string
  phone?: string
  created_at: string
}

// API-respons (alle server actions returnerer dette)
export interface IApiResponse<T = unknown> {
  success: boolean
  message?: string
  data?: T
}

// Kontaktmelding
export interface IContactMessage {
  id: number
  name: string
  email: string
  phone?: string
  message: string
  is_read: boolean
  created_at: string
}

// Generisk innhold (produkter, tjenester, etc.)
export interface IContent {
  id: number
  type: string
  title: string
  description?: string
  image_url?: string
  price?: number
  is_active: boolean
  sort_order: number
  created_at: string
}
EOF

# Zustand store
cat > src/store/users-store.ts << 'EOF'
import { create } from "zustand"
import { IUser } from "@/interfaces"

interface UsersStore {
  user: IUser | null
  setUser: (user: IUser) => void
  clearUser: () => void
}

const useUsersStore = create<UsersStore>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
}))

export default useUsersStore
EOF

print_success "Konfigurasjonsfiler opprettet"

# ============================================================
# STEG 5: OPPRETT SERVER ACTIONS
# ============================================================
echo ""
echo -e "${YELLOW}[5/7] Oppretter Server Actions...${NC}"

# Auth actions
cat > src/actions/auth.ts << 'EOF'
"use server"

import bcrypt from "bcryptjs"
import jwt from "jsonwebtoken"
import { cookies } from "next/headers"
import supabase from "@/config/supabase-config"
import { IApiResponse, IUser } from "@/interfaces"

export async function register(payload: {
  name: string
  email: string
  password: string
}): Promise<IApiResponse> {
  try {
    // Sjekk om e-post finnes
    const { data: existing } = await supabase
      .from("users")
      .select("id")
      .eq("email", payload.email)
      .single()

    if (existing) {
      return { success: false, message: "E-post er allerede registrert" }
    }

    // Hash passord
    const hashedPassword = await bcrypt.hash(payload.password, 10)

    // Opprett bruker
    const { error } = await supabase.from("users").insert({
      name: payload.name,
      email: payload.email,
      password: hashedPassword,
    })

    if (error) throw error

    return { success: true, message: "Bruker opprettet!" }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Ukjent feil"
    return { success: false, message }
  }
}

export async function login(payload: {
  email: string
  password: string
}): Promise<IApiResponse> {
  try {
    // Finn bruker
    const { data: user, error } = await supabase
      .from("users")
      .select("*")
      .eq("email", payload.email)
      .single()

    if (error || !user) {
      return { success: false, message: "Ugyldig e-post eller passord" }
    }

    // Verifiser passord
    const isValid = await bcrypt.compare(payload.password, user.password)

    if (!isValid) {
      return { success: false, message: "Ugyldig e-post eller passord" }
    }

    // Generer JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET!,
      { expiresIn: "7d" }
    )

    // Lagre i cookie
    const cookieStore = await cookies()
    cookieStore.set("token", token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 60 * 60 * 24 * 7, // 7 dager
    })

    return { success: true, message: "Innlogget!" }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Ukjent feil"
    return { success: false, message }
  }
}

export async function getLoggedInUser(): Promise<IApiResponse<IUser>> {
  try {
    const cookieStore = await cookies()
    const token = cookieStore.get("token")?.value

    if (!token) {
      return { success: false, message: "Ikke innlogget" }
    }

    // Verifiser token
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as {
      userId: number
    }

    // Hent bruker
    const { data: user, error } = await supabase
      .from("users")
      .select("id, name, email, role")
      .eq("id", decoded.userId)
      .single()

    if (error || !user) {
      return { success: false, message: "Bruker ikke funnet" }
    }

    return { success: true, data: user }
  } catch {
    return { success: false, message: "Ugyldig sesjon" }
  }
}

export async function logout(): Promise<IApiResponse> {
  const cookieStore = await cookies()
  cookieStore.delete("token")
  return { success: true }
}
EOF

# Contact actions
cat > src/actions/contact.ts << 'EOF'
"use server"

import supabase from "@/config/supabase-config"
import { IApiResponse, IContactMessage } from "@/interfaces"

export async function submitContact(payload: {
  name: string
  email: string
  phone?: string
  message: string
}): Promise<IApiResponse> {
  try {
    const { error } = await supabase
      .from("contact_messages")
      .insert(payload)

    if (error) throw error

    return { success: true, message: "Takk! Vi kontakter deg snart." }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Noe gikk galt"
    return { success: false, message }
  }
}

export async function getMessages(): Promise<IApiResponse<IContactMessage[]>> {
  try {
    const { data, error } = await supabase
      .from("contact_messages")
      .select("*")
      .order("created_at", { ascending: false })

    if (error) throw error

    return { success: true, data }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Kunne ikke hente meldinger"
    return { success: false, message, data: [] }
  }
}

export async function markAsRead(id: number): Promise<IApiResponse> {
  try {
    const { error } = await supabase
      .from("contact_messages")
      .update({ is_read: true })
      .eq("id", id)

    if (error) throw error

    return { success: true }
  } catch {
    return { success: false }
  }
}
EOF

print_success "Server Actions opprettet"

# ============================================================
# STEG 6: OPPRETT PROXY.TS OG KOMPONENTER
# ============================================================
echo ""
echo -e "${YELLOW}[6/7] Oppretter proxy.ts og komponenter...${NC}"

# proxy.ts (Next.js 16 middleware)
cat > src/proxy.ts << 'EOF'
// src/proxy.ts (Next.js 16+)
// Erstatter middleware.ts fra tidligere versjoner
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export function proxy(request: NextRequest) {
  const token = request.cookies.get("token")?.value
  const path = request.nextUrl.pathname

  // Beskyttede ruter
  const protectedRoutes = ["/admin", "/dashboard", "/profile"]
  const isProtected = protectedRoutes.some((route) => path.startsWith(route))

  // Auth-ruter (login/register)
  const authRoutes = ["/login", "/register"]
  const isAuthRoute = authRoutes.includes(path)

  // Ikke innlogget, prøver beskyttet rute
  if (isProtected && !token) {
    return NextResponse.redirect(new URL("/login", request.url))
  }

  // Innlogget, prøver auth-rute
  if (isAuthRoute && token) {
    return NextResponse.redirect(new URL("/dashboard", request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/admin/:path*", "/dashboard/:path*", "/profile/:path*", "/login", "/register"],
}
EOF

# Header komponent
cat > src/components/layout/header.tsx << 'EOF'
import Link from "next/link"

export default function Header() {
  return (
    <header className="bg-white border-b sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
        <Link href="/" className="text-xl font-bold text-blue-600">
          Logo
        </Link>

        <nav className="hidden md:flex gap-6">
          <Link href="/" className="hover:text-blue-600 transition-colors">Hjem</Link>
          <Link href="/om-oss" className="hover:text-blue-600 transition-colors">Om oss</Link>
          <Link href="/tjenester" className="hover:text-blue-600 transition-colors">Tjenester</Link>
          <Link href="/kontakt" className="hover:text-blue-600 transition-colors">Kontakt</Link>
        </nav>

        <Link
          href="/kontakt"
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          Kontakt oss
        </Link>
      </div>
    </header>
  )
}
EOF

# Footer komponent
cat > src/components/layout/footer.tsx << 'EOF'
import Link from "next/link"

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-white py-12">
      <div className="max-w-6xl mx-auto px-4 grid grid-cols-1 md:grid-cols-3 gap-8">
        <div>
          <h3 className="text-lg font-bold mb-4">Firmanavn</h3>
          <p className="text-gray-400">
            En kort beskrivelse av bedriften.
          </p>
        </div>

        <div>
          <h3 className="text-lg font-bold mb-4">Kontakt</h3>
          <p className="text-gray-400">post@eksempel.no</p>
          <p className="text-gray-400">+47 123 45 678</p>
        </div>

        <div>
          <h3 className="text-lg font-bold mb-4">Lenker</h3>
          <div className="flex flex-col gap-2">
            <Link href="/personvern" className="text-gray-400 hover:text-white transition-colors">
              Personvern
            </Link>
            <Link href="/vilkar" className="text-gray-400 hover:text-white transition-colors">
              Vilkår
            </Link>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-4 pt-8 mt-8 border-t border-gray-800 text-center text-gray-400">
        © {new Date().getFullYear()} Firmanavn. Alle rettigheter reservert.
        <br />
        <span className="text-sm">Utviklet av <a href="https://obligarconsulting.no" className="text-blue-400 hover:underline">Obligar Consulting</a></span>
      </div>
    </footer>
  )
}
EOF

# Button komponent
cat > src/components/ui/button.tsx << 'EOF'
import { forwardRef, ButtonHTMLAttributes } from "react"
import { cn } from "@/lib/utils"

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "default" | "outline" | "ghost" | "destructive"
  size?: "default" | "sm" | "lg"
}

const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "default", size = "default", ...props }, ref) => {
    return (
      <button
        className={cn(
          "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
          {
            "bg-blue-600 text-white hover:bg-blue-700": variant === "default",
            "border border-gray-300 bg-transparent hover:bg-gray-100": variant === "outline",
            "hover:bg-gray-100": variant === "ghost",
            "bg-red-600 text-white hover:bg-red-700": variant === "destructive",
          },
          {
            "h-10 px-4 py-2": size === "default",
            "h-8 px-3 text-sm": size === "sm",
            "h-12 px-6 text-lg": size === "lg",
          },
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button }
EOF

# Input komponent
cat > src/components/ui/input.tsx << 'EOF'
import { forwardRef, InputHTMLAttributes } from "react"
import { cn } from "@/lib/utils"

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {}

const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, ...props }, ref) => {
    return (
      <input
        className={cn(
          "flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input }
EOF

print_success "Proxy.ts og komponenter opprettet"

# ============================================================
# STEG 7: OPPDATER LAYOUT OG FORSIDE
# ============================================================
echo ""
echo -e "${YELLOW}[7/7] Oppdaterer layout og forside...${NC}"

# Oppdater layout.tsx
cat > src/app/layout.tsx << 'EOF'
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import { Toaster } from "react-hot-toast"
import Header from "@/components/layout/header"
import Footer from "@/components/layout/footer"
import "./globals.css"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "Firmanavn - Beskrivelse",
  description: "En kort beskrivelse for SEO",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="no">
      <body className={inter.className}>
        <Toaster position="top-right" />
        <Header />
        <main className="min-h-screen">{children}</main>
        <Footer />
      </body>
    </html>
  )
}
EOF

# Oppdater forsiden
cat > src/app/page.tsx << 'EOF'
import Link from "next/link"

export default function HomePage() {
  return (
    <>
      {/* Hero Section */}
      <section className="bg-gradient-to-r from-blue-600 to-blue-800 text-white py-20">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-bold mb-6">
            Velkommen til Firmanavn
          </h1>
          <p className="text-xl text-blue-100 mb-8 max-w-2xl mx-auto">
            En kort setning som forklarer hva bedriften gjør og hvorfor kunden bør velge dem.
          </p>
          <div className="flex gap-4 justify-center flex-wrap">
            <Link
              href="/kontakt"
              className="bg-white text-blue-600 px-6 py-3 rounded-md font-medium hover:bg-gray-100 transition-colors"
            >
              Kontakt oss
            </Link>
            <Link
              href="/tjenester"
              className="border border-white text-white px-6 py-3 rounded-md font-medium hover:bg-white/10 transition-colors"
            >
              Se tjenester
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20">
        <div className="max-w-6xl mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">Hvorfor velge oss</h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              { title: "Fordel 1", desc: "Beskrivelse av første fordel" },
              { title: "Fordel 2", desc: "Beskrivelse av andre fordel" },
              { title: "Fordel 3", desc: "Beskrivelse av tredje fordel" },
            ].map((item, i) => (
              <div key={i} className="bg-white p-6 rounded-lg border shadow-sm hover:shadow-md transition-shadow">
                <div className="w-12 h-12 bg-blue-100 rounded-lg mb-4 flex items-center justify-center text-blue-600 font-bold">
                  {i + 1}
                </div>
                <h3 className="text-xl font-semibold mb-2">{item.title}</h3>
                <p className="text-gray-600">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-gray-100 py-20">
        <div className="max-w-6xl mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">Klar til å komme i gang?</h2>
          <p className="text-gray-600 mb-8">Ta kontakt for en uforpliktende prat.</p>
          <Link
            href="/kontakt"
            className="bg-blue-600 text-white px-8 py-3 rounded-md font-medium hover:bg-blue-700 transition-colors inline-block"
          >
            Kontakt oss i dag
          </Link>
        </div>
      </section>
    </>
  )
}
EOF

print_success "Layout og forside oppdatert"

# ============================================================
# FERDIG - VIS OPPSUMMERING
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗"
echo "║              PROSJEKT OPPRETTET VELLYKKET!               ║"
echo "╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Neste steg:${NC}"
echo ""
echo "  1. Gå til prosjektmappen:"
echo "     ${CYAN}cd $PROJECT_NAME${NC}"
echo ""
echo "  2. Rediger .env.local med Supabase-nøkler:"
echo "     ${CYAN}open .env.local${NC}  (Mac)"
echo "     ${CYAN}code .env.local${NC}  (VS Code)"
echo ""
echo "  3. Start utviklingsserver:"
echo "     ${CYAN}npm run dev${NC}"
echo ""
echo "  4. Åpne i nettleser:"
echo "     ${CYAN}http://localhost:3000${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  SUPABASE SQL (kjør i SQL Editor):${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
cat << 'SQLEOF'
-- Brukertabell
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  role VARCHAR(50) DEFAULT 'user',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Kontaktmeldinger
CREATE TABLE contact_messages (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all" ON users FOR ALL USING (true);
CREATE POLICY "Allow all" ON contact_messages FOR ALL USING (true);
SQLEOF
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Utviklet av Obligar Consulting${NC}"
echo -e "${GREEN}  https://obligarconsulting.no${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
