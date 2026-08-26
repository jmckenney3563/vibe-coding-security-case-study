-- ==============================================================================
-- SYNTHETIC SECURITY RESEARCH LAB ONLY: DO NOT USE IN PRODUCTION
-- Pattern: AI-Generated Rapid Prototype Schema (Missing RLS & Logic Inversion)
-- Reference: CS-2026-VIBECODE-01 (Lovable / Supabase Vulnerability Analysis)
-- ==============================================================================

-- 1. Table Creation without Row Level Security
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT DEFAULT 'student',
    school_organization TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.exam_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    exam_title TEXT NOT NULL,
    submission_content TEXT,
    grade TEXT DEFAULT 'PENDING',
    graded_by UUID,
    submitted_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- CRITICAL DEFECT: Unrestricted API exposure via PostgREST
-- Anonymous (anon) and authenticated roles granted full privileges
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT ALL ON public.exam_submissions TO anon, authenticated;

-- CRITICAL DEFECT: Row Level Security is NOT enabled
-- Result: Anyone with the public anon key can run `SELECT * FROM user_profiles`

-- 2. Flawed Administrative RPC with Logic Inversion
CREATE OR REPLACE FUNCTION public.admin_modify_user_grade(
    target_student_id UUID,
    new_grade TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- Executes with database owner privileges
SET search_path = public
AS $$
BEGIN
    -- LOGIC INVERSION FLAW:
    -- AI intended to guard admin access, but inverted the null check:
    -- If caller is authenticated (auth.uid() IS NOT NULL), it throws an exception.
    -- If caller is anonymous (auth.uid() IS NULL), the check evaluates to FALSE,
    -- allowing unauthenticated attackers to execute grade modifications!
    IF (auth.uid() IS NOT NULL) THEN
        RAISE EXCEPTION 'Access Denied: Restricted Operation';
    END IF;

    UPDATE public.exam_submissions
    SET grade = new_grade, updated_at = now()
    WHERE student_id = target_student_id;

    RETURN jsonb_build_object('success', true, 'message', 'Grade updated');
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_modify_user_grade TO anon, authenticated;
