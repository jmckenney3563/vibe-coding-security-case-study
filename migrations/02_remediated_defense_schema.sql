-- ==============================================================================
-- PRODUCTION DEFENSE SPECIFICATION: SECURE HARDENED SCHEMA
-- Reference: CS-2026-VIBECODE-01 (Lovable / Supabase Vulnerability Analysis)
-- ==============================================================================

-- 1. Hardened Table Definitions with Strict Type Constraints
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
    school_organization TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_user_id UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS public.exam_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    exam_title TEXT NOT NULL,
    submission_content TEXT NOT NULL,
    grade TEXT NOT NULL DEFAULT 'PENDING',
    graded_by UUID REFERENCES public.user_profiles(id),
    submitted_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Mandatory Row Level Security (RLS) Enforcement
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles FORCE ROW LEVEL SECURITY;

ALTER TABLE public.exam_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_submissions FORCE ROW LEVEL SECURITY;

-- 3. Least-Privilege Grants
REVOKE ALL ON public.user_profiles FROM PUBLIC, anon;
REVOKE ALL ON public.exam_submissions FROM PUBLIC, anon;

GRANT SELECT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT ON public.exam_submissions TO authenticated;

-- 4. Granular RLS Policies for user_profiles
DROP POLICY IF EXISTS "users_read_own_or_org_profile" ON public.user_profiles;
CREATE POLICY "users_read_own_or_org_profile" ON public.user_profiles
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.user_id = auth.uid() 
              AND p.role IN ('instructor', 'admin')
              AND p.school_organization = user_profiles.school_organization
        )
    );

DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
CREATE POLICY "users_update_own_profile" ON public.user_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (
        auth.uid() = user_id 
        AND role = (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
    );

-- 5. Granular RLS Policies for exam_submissions
DROP POLICY IF EXISTS "students_manage_own_submissions" ON public.exam_submissions;
CREATE POLICY "students_manage_own_submissions" ON public.exam_submissions
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = exam_submissions.student_id
              AND p.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "instructors_read_org_submissions" ON public.exam_submissions;
CREATE POLICY "instructors_read_org_submissions" ON public.exam_submissions
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles target_student
            JOIN public.user_profiles caller_profile 
              ON caller_profile.school_organization = target_student.school_organization
            WHERE target_student.id = exam_submissions.student_id
              AND caller_profile.user_id = auth.uid()
              AND caller_profile.role IN ('instructor', 'admin')
        )
    );

-- 6. Remediated RPC Function with Strict Authentication & Authorization Guard
CREATE OR REPLACE FUNCTION public.admin_modify_user_grade(
    target_student_id UUID,
    new_grade TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp -- Prevent search_path manipulation
AS $$
DECLARE
    current_caller_id UUID;
    caller_is_admin BOOLEAN;
BEGIN
    -- [GUARD 1] Enforce caller authentication
    current_caller_id := auth.uid();
    IF current_caller_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller must be authenticated'
            USING ERRCODE = '28000';
    END IF;

    -- [GUARD 2] Enforce role-based access control (RBAC)
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE user_id = current_caller_id
          AND role IN ('instructor', 'admin')
    ) INTO caller_is_admin;

    IF NOT caller_is_admin THEN
        RAISE EXCEPTION 'Forbidden: Insufficient privileges to alter examination records'
            USING ERRCODE = '42501';
    END IF;

    -- [OPERATION] Execute parameterized mutation
    UPDATE public.exam_submissions
    SET grade = new_grade,
        graded_by = (SELECT id FROM public.user_profiles WHERE user_id = current_caller_id),
        updated_at = now()
    WHERE student_id = target_student_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Record not found for student profile %', target_student_id
            USING ERRCODE = 'P0002';
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'student_id', target_student_id,
        'updated_by', current_caller_id,
        'timestamp', now()
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_modify_user_grade FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_modify_user_grade TO authenticated;
