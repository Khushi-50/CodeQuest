# 🌐 CodeQuest — 5-Minute Live Deployment Guide

Follow this guide to host **CodeQuest** live so recruiters can open your project in any web browser via a live link (`https://codequest.vercel.app`).

---

## 🛰️ Step 1: Deploy Backend to Render (Free)

1. Push your repository to **GitHub**.
2. Sign in to [Render.com](https://render.com).
3. Click **New +** $\rightarrow$ **Blueprint**.
4. Connect your GitHub repository. Render will automatically detect `codequest_backend/render.yaml`.
5. Under Environment Variables in Render:
   - Set `MONGODB_URI` to your free MongoDB Atlas connection string (e.g. `mongodb+srv://<user>:<password>@cluster0.mongodb.net/codequest`).
6. Click **Apply**. Render will deploy your backend to `https://codequest-backend.onrender.com`.

---

## ⚡ Step 2: Seed Production Database

Once the backend is live on Render:
```bash
# Seed default CS courses, vault chapters, and breach quizzes directly to MongoDB Atlas
MONGODB_URI="your_mongodb_atlas_connection_string" npm run seed
```

---

## 🚀 Step 3: Deploy Frontend to Vercel (Free)

### Option A: Automatic Vercel GitHub Deployment (Recommended)
1. Sign in to [Vercel](https://vercel.com).
2. Click **Add New** $\rightarrow$ **Project** and import your GitHub repository.
3. Set **Framework Preset** to `Other`.
4. Set **Root Directory** to `codequest_frontend`.
5. Set **Build Command** to:
   ```bash
   if [ -d "flutter" ]; then echo "Flutter exists"; else git clone https://github.com/flutter/flutter.git -b stable; fi && export PATH="$PATH:`pwd`/flutter/bin" && flutter build web --release
   ```
6. Set **Output Directory** to `build/web`.
7. Click **Deploy**. Vercel will give you a live production link e.g. `https://codequest.vercel.app`!

### Option B: Local CLI Deployment (Fastest)
If you have `vercel` CLI installed locally:
```bash
# Build the Flutter web bundle locally
cd codequest_frontend
flutter build web --release

# Deploy the output directory directly
cd build/web
npx vercel --prod
```

---

## 🎯 Showing to Recruiters

When sharing with recruiters:
1. Provide your live web link: `https://codequest.vercel.app`
2. Point out that the web interface automatically presents the app inside a **Responsive Cyberdeck Terminal HUD**, making it look like a futuristic desktop application on desktop screens while remaining responsive on mobile.
3. Link your GitHub repository featuring the architecture diagram and API spec in `README.md`.
