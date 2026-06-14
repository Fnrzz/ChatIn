# ChatIn Landing Page 🌐

Public-facing marketing and download page built with **Next.js 16** and **Tailwind CSS 4**.

---

## 🌟 Overview

Landing page untuk aplikasi ChatIn — menampilkan hero section dengan mockup aplikasi, call-to-action buttons, dan informasi rating di App Store & Google Play.

---

## ⚡ Tech Stack

| Package         | Version  | Purpose                       |
| --------------- | -------- | ----------------------------- |
| `next`          | 16.2.9   | React framework (App Router)  |
| `react`         | 19.2.4   | UI library                    |
| `tailwindcss`   | ^4       | Utility-first CSS framework   |
| `lucide-react`  | ^1.18.0  | Icon library                  |

---

## 📂 Project Structure

```
src/
├── app/
│   ├── layout.tsx           # Root layout (Geist fonts, Navbar)
│   ├── page.tsx             # Landing page (renders Hero)
│   ├── globals.css          # Global styles & Tailwind imports
│   └── favicon.ico          # App favicon
└── components/
    ├── Navbar.tsx            # Fixed navbar with logo, nav links, auth buttons
    └── Hero.tsx              # Hero section: headline, CTA, ratings, mockup

public/
├── app_logo.png             # ChatIn logo
├── background/
│   └── background-hero.avif # Hero background image
├── mockup/
│   └── homepage-new.avif    # App mockup screenshot
└── svg/
    ├── appstore.svg          # App Store badge
    └── googleplay.svg        # Google Play badge
```

---

## 🔑 Features

- **Hero Section** — Full-screen hero dengan background image dan overlay
- **App Mockup** — Phone mockup menampilkan screenshot aplikasi
- **CTA Buttons** — "Get 14-days free trial" & "Download the app"
- **Store Ratings** — Badge App Store & Google Play dengan rating
- **Glassmorphism** — Modern `backdrop-blur` effects pada buttons dan navbar
- **Responsive** — Layout yang menyesuaikan desktop & mobile
- **Fixed Navbar** — Navigation bar yang tetap di atas saat scroll

---

## 🚀 Getting Started

### Prerequisites

- Node.js `>= 18`

### Setup

```bash
# Navigate to the landing page directory
cd chatin-landingpage

# Install dependencies
npm install

# Run development server
npm run dev
```

Landing page akan berjalan di `http://localhost:3000` (atau port berikutnya jika 3000 sudah digunakan).

---

## 🎨 Design

- **Font**: Geist Sans & Geist Mono (via `next/font/google`)
- **Background**: Full-bleed hero image dengan dark overlay (`bg-black/40`)
- **Colors**: Dark green primary (`#0E3524`), white text, glass effects
- **Style**: Modern glassmorphism dengan `backdrop-blur-md` dan `border-white/40`

---

## 📝 Sections (Current)

| Section   | Status | Description                                      |
| --------- | ------ | ------------------------------------------------ |
| Navbar    | ✅     | Logo, nav links (Home, Features, Pricing, About) |
| Hero      | ✅     | Headline, subtitle, CTAs, store ratings, mockup  |
| Features  | 🔜     | App feature highlights                           |
| Pricing   | 🔜     | Subscription plan comparison                     |
| About     | 🔜     | About the app & team                             |
| Footer    | 🔜     | Links, social media, copyright                   |
