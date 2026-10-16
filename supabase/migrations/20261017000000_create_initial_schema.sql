-- Migration: 20261017000000_create_initial_schema.sql
-- Description: Creates initial schema for Glucio (products, food_logs, profiles, reports) with RLS policies

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    barcode TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    category TEXT,
    pack_size_g NUMERIC,
    serving_size_g NUMERIC,
    sugar_per_100g NUMERIC NOT NULL,
    added_sugar_per_100g NUMERIC,
    ingredients_text TEXT,
    hidden_sugar_flag BOOLEAN DEFAULT FALSE,
    source TEXT NOT NULL CHECK (source IN ('seed', 'openfoodfacts', 'user')),
    verified BOOLEAN DEFAULT FALSE,
    label_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Profiles Table (user daily limit)
CREATE TABLE IF NOT EXISTS public.profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_limit_g NUMERIC DEFAULT 25.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Food Logs Table (user consumption log)
CREATE TABLE IF NOT EXISTS public.food_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    barcode TEXT NOT NULL REFERENCES public.products(barcode) ON DELETE RESTRICT,
    servings NUMERIC NOT NULL DEFAULT 1.0,
    sugar_g NUMERIC NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Reports Table (user reporting incorrect data)
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Enable Row Level Security (RLS) on all tables
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies

-- Products: Everyone can read
CREATE POLICY "Products are viewable by everyone" 
ON public.products FOR SELECT 
USING (true);

-- Products: Users can insert unverified products
CREATE POLICY "Users can contribute unverified products" 
ON public.products FOR INSERT 
WITH CHECK (verified = false);

-- Profiles: Users manage their own profile
CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Food Logs: Users manage their own food logs
CREATE POLICY "Users can view own food logs" 
ON public.food_logs FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food logs" 
ON public.food_logs FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own food logs" 
ON public.food_logs FOR DELETE 
USING (auth.uid() = user_id);

-- Reports: Anyone authenticated or anonymous can submit reports
CREATE POLICY "Anyone can submit a report" 
ON public.reports FOR INSERT 
WITH CHECK (true);
