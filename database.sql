-- Study Group.tn NEW SUPABASE PROJECT ONLY.
-- Run in SQL Editor. This script creates a new schema; do not run over existing tables.
create extension if not exists pgcrypto;
create table public.student_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 first_name text not null check(length(trim(first_name)) between 1 and 60),
 last_name text not null check(length(trim(last_name)) between 1 and 60),
 school_year text not null check(school_year in ('7base','8base','9base','1ere','2eme','3eme','4eme')),
 section text,
 optional_language text,
 created_at timestamptz not null default now(),
 constraint valid_section check(
 (school_year in ('7base','8base','9base','1ere') and section is null) or
 (school_year='2eme' and section in ('sciences','lettres','economie','informatique')) or
 (school_year in ('3eme','4eme') and section in ('sciences','mathematiques','lettres','economie','technique','informatique','sport'))),
 constraint valid_optional check(
 (school_year not in ('3eme','4eme') and optional_language is null) or
 (school_year in ('3eme','4eme') and optional_language in ('es','it','de','zh','tr','art','music')))
);
create table public.resources (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check(length(trim(title)) between 1 and 180),
 subject text not null,
 category text not null check(category in ('Résumés','Cours','Séries','Exercices')),
 school_year text not null,
 section text,
 optional_language text,
 storage_path text not null unique,
 created_at timestamptz not null default now(),
 constraint resource_year check(school_year in ('7base','8base','9base','1ere','2eme','3eme','4eme')),
 constraint optional_subject_match check (
 (optional_language is null and subject not in ('Espagnol','Italien','Allemand','Chinois','Turc','Arts plastiques','Musique')) or
 (optional_language='es' and subject='Espagnol') or
 (optional_language='it' and subject='Italien') or
 (optional_language='de' and subject='Allemand') or
 (optional_language='zh' and subject='Chinois') or
 (optional_language='tr' and subject='Turc') or
 (optional_language='art' and subject='Arts plastiques') or
 (optional_language='music' and subject='Musique'))
);
create index resources_filter_idx on public.resources(school_year,section,optional_language,subject,category);
alter table public.student_profiles enable row level security;
alter table public.resources enable row level security;
create policy "read own profile" on public.student_profiles for select to authenticated using (id=(select auth.uid()));
create policy "insert own profile" on public.student_profiles for insert to authenticated with check (id=(select auth.uid()));
-- Students cannot update their confirmed profile. Administrative changes require a separate privileged workflow.
create or replace function public.same_student_scope(y text,s text,o text,sub text)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.student_profiles p where p.id=(select auth.uid())
 and p.school_year=y and p.section is not distinct from s
 and (o is null or p.optional_language=o)
 and (o is null or (p.school_year in ('3eme','4eme') and sub in ('Espagnol','Italien','Allemand','Chinois','Turc','Arts plastiques','Musique')))
 );
$$;
revoke all on function public.same_student_scope(text,text,text,text) from public;
grant execute on function public.same_student_scope(text,text,text,text) to authenticated;
-- An optional-subject resource is accessible only to students with that exact option.
-- Regular resources have optional_language NULL and are visible to everyone in the same year/section.
create policy "read scoped resources" on public.resources for select to authenticated
using(public.same_student_scope(school_year,section,optional_language,subject));
create policy "insert scoped resources" on public.resources for insert to authenticated
with check(owner_id=(select auth.uid()) and public.same_student_scope(school_year,section,optional_language,subject)
 and storage_path like ((select auth.uid())::text || '/%'));
-- No client-side updates/deletes; moderation and cleanup can be implemented via admin-only backend.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('resources','resources',false,10485760,array['application/pdf','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.ms-powerpoint','application/vnd.openxmlformats-officedocument.presentationml.presentation','image/png','image/jpeg'])
on conflict (id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
-- Restrict storage read to paths belonging to resources the student can see.
create policy "download scoped objects" on storage.objects for select to authenticated
using(bucket_id='resources' and exists(
 select 1 from public.resources r where r.storage_path=name
 and public.same_student_scope(r.school_year,r.section,r.optional_language,r.subject)));
-- Uploads must be inside the authenticated student's private folder.
create policy "upload own folder" on storage.objects for insert to authenticated
with check(bucket_id='resources' and (storage.foldername(name))[1]=(select auth.uid())::text
 and exists(select 1 from public.student_profiles p where p.id=(select auth.uid())));
-- NOTE: validate subject against an authoritative curriculum list server-side before production.
-- NOTE: orphan files from failed metadata inserts require periodic admin cleanup.
