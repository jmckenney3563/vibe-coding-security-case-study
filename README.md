# Real-World Systems & Cybersecurity Case Studies Repository

An open-source research and systems engineering repository documenting root-cause investigations, failure modes, threat modeling, and production-grade remediations for modern software failures and AI-generated systems.

---

## 📚 Published Case Studies

| ID | Case Study Title | Sector / Domain | Primary Impact | Technical Failure Modes | Document |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **CS-01** | **The "Vibe Coding" Security Dilemma** | Full-Stack AI Development | 18,697 Exposed Educational Records | Missing Postgres RLS, Logic Inversion in Supabase RPCs, Client-Side Auth Illusions | [View Study](./studies/01-lovable-vibe-coding-security.md) |
| **CS-02** | **Public Sector EdTech Transportation Collapse** | Municipal IoT & Fleet Routing | 10,000+ Stranded Students, 1,100 Bus Fleet | Route Invariant Failure (AM/PM Asymmetry), Thundering Herd on Tracking API, Missing Edge Caching | [View Study](./studies/02-pgcps-transportation-routing-failure.md) |

---

## 🔍 Featured Case Study Overviews

### 1. [Case Study 01: Lovable / Supabase Vibe-Coding Vulnerabilities](./studies/01-lovable-vibe-coding-security.md)
* **Incident Scope**: An application generated via rapid AI prototyping on the Lovable platform exposed over 18,000 student and teacher records.
* **Core Vulnerability**: The AI scaffolded PostgREST database tables without enabling PostgreSQL Row-Level Security (RLS) and generated an administrative remote procedure call (`SECURITY DEFINER`) with inverted boolean authorization logic.
* **Key Artifacts**:
  * Synthetic reproduction: [`migrations/01_vulnerable_schema.sql`](./migrations/01_vulnerable_schema.sql)
  * Hardened defense schema: [`migrations/02_remediated_defense_schema.sql`](./migrations/02_remediated_defense_schema.sql)
  * CI/CD compliance linter: [`.github/workflows/security-lint.yml`](./.github/workflows/security-lint.yml)

### 2. [Case Study 02: PGCPS Fleet Routing & Chipmunk Telematics Collapse](./studies/02-pgcps-transportation-routing-failure.md)
* **Incident Scope**: Day-one transportation collapse across Prince George's County Public Schools leaving 10,000+ students without bus transit.
* **Core Failure Modes**:
  * **Constraint Solver Invariant Breach**: VRP compiler committed asymmetric schedules (PM drop-off without AM pickup).
  * **Thundering Herd API Crash**: Direct relational database polling by 50k+ concurrent parents on the "Chipmunk" GPS mobile app without edge caching or WebSocket fanout.
  * **Operational Readiness**: Insufficient district-wide dry runs and staff training prior to production cutover.
* **Key Remediation**: Invariant-enforcing route compilation algorithms and Redis Geo-spatial edge caching.

---

## 🛠️ Repository Structure

```
.
├── README.md                                 # Case studies portal and executive overview
├── SECURITY.md                               # Responsible disclosure & educational disclaimer
├── .github/
│   └── workflows/
│       └── security-lint.yml                 # Automated CI/CD security and RLS policy audit
├── migrations/
│   ├── 01_vulnerable_schema.sql              # Synthetic PoC of AI-generated flaws
│   └── 02_remediated_defense_schema.sql      # Production-hardened PostgreSQL defense
└── studies/
    ├── 01-lovable-vibe-coding-security.md    # Full report on Lovable / Supabase vulnerability
    └── 02-pgcps-transportation-routing-failure.md # Full post-mortem on PGCPS transit failure
```

---

## 🛡️ Research & Educational Notice
All research artifacts and migration files in this repository are **synthetic reconstructions** designed for security engineering, academic research, and resilience benchmarking. See [`SECURITY.md`](./SECURITY.md) for policies and disclosure standards.
