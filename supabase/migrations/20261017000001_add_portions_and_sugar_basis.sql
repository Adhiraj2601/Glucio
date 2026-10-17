-- Migration: 20261017000001_add_portions_and_sugar_basis.sql
-- Description: Adds portions JSONB, sugar_basis column, and makes sugar_per_100g nullable

-- 1. Make sugar_per_100g nullable to strictly forbid defaulting missing nutrition data to 0
ALTER TABLE public.products 
    ALTER COLUMN sugar_per_100g DROP NOT NULL;

-- 2. Add sugar_basis column ('per_100g' or 'per_100ml')
ALTER TABLE public.products 
    ADD COLUMN IF NOT EXISTS sugar_basis TEXT DEFAULT 'per_100g' 
    CHECK (sugar_basis IN ('per_100g', 'per_100ml'));

-- 3. Add portions JSONB column for natural household portions:
-- Example format:
-- [
--   {"label": "1 biscuit", "amount": 10.0, "basis": "g", "kind": "unit", "source": "label"},
--   {"label": "1 serving", "amount": 25.0, "basis": "g", "kind": "serving", "source": "label"},
--   {"label": "Whole pack", "amount": 250.0, "basis": "g", "kind": "pack", "source": "label"}
-- ]
ALTER TABLE public.products 
    ADD COLUMN IF NOT EXISTS portions JSONB DEFAULT '[]'::jsonb;

-- 4. Update comment on columns
COMMENT ON COLUMN public.products.sugar_per_100g IS 'Total sugar per 100g/ml. Nullable: strictly null when unknown/missing from label.';
COMMENT ON COLUMN public.products.sugar_basis IS 'Measurement basis: per_100g for solids, per_100ml for liquids.';
COMMENT ON COLUMN public.products.portions IS 'Array of household portion definitions (label, amount, basis, kind, source).';
