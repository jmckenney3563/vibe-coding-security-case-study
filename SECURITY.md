# Security Policy & Educational Disclosure Notice

## Research Scope & Disclaimer
This repository contains educational research artifacts, threat modeling, and synthetic proof-of-concept migration scripts analyzing security failure modes in AI-assisted full-stack rapid prototyping ("vibe coding") platforms.

- All code samples in `migrations/01_vulnerable_schema.sql` are **synthetic representations** designed for isolated security testing and instructional remediation.
- No actual production credentials, customer records, database connection strings, or proprietary source code from any vendor or user are included.

## Defense-in-Depth Guidelines for AI-Assisted Developers
1. **Never Trust AI Database Schemas Without Explicit RLS**: Always verify `ALTER TABLE <name> ENABLE ROW LEVEL SECURITY;` on every public Postgres entity.
2. **Audit RPC Function Logic**: Never mark functions `SECURITY DEFINER` without rigorous authentication (`auth.uid() IS NOT NULL`) and authorization checks.
3. **Automate Pre-Commit Linting**: Run database AST checkers and policy validators before deploying to production environments.
