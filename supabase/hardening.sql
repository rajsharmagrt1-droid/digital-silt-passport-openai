-- Run after schema.sql in Supabase SQL Editor.
-- Security hardening + admin functions + audit trail.

create or replace function public.is_approved_staff()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.staff_profiles where user_id=auth.uid() and approved=true);
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.staff_profiles where user_id=auth.uid() and approved=true and role='admin');
$$;

drop policy if exists "admin can manage reaches" on public.reaches;
create policy "admin can manage reaches" on public.reaches
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin can manage verifications" on public.verifications;
create policy "admin can manage verifications" on public.verifications
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admin can read audit log" on public.audit_log;
create policy "admin can read audit log" on public.audit_log
for select to authenticated using (public.is_admin());

create or replace function public.admin_list_staff()
returns setof public.staff_profiles
language sql stable security definer set search_path=public as $$
  select * from public.staff_profiles where public.is_admin();
$$;

create or replace function public.admin_set_staff_approval(target_user_id uuid,new_approved boolean)
returns public.staff_profiles
language plpgsql security definer set search_path=public as $$
declare result public.staff_profiles;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  update public.staff_profiles set approved=new_approved where user_id=target_user_id returning * into result;
  if result.user_id is null then raise exception 'Staff profile not found'; end if;
  return result;
end $$;

grant execute on function public.admin_list_staff() to authenticated;
grant execute on function public.admin_set_staff_approval(uuid,boolean) to authenticated;

create or replace function public.write_audit()
returns trigger language plpgsql security definer set search_path=public as $$
declare rid uuid;
begin
  if TG_TABLE_NAME='staff_profiles' then
    rid:=case when TG_OP='DELETE' then old.user_id else new.user_id end;
  else
    rid:=case when TG_OP='DELETE' then old.id else new.id end;
  end if;
  insert into public.audit_log(actor_id,action,table_name,record_id,old_data,new_data)
  values(auth.uid(),TG_OP,TG_TABLE_NAME,rid,
    case when TG_OP in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when TG_OP in ('INSERT','UPDATE') then to_jsonb(new) end);
  return case when TG_OP='DELETE' then old else new end;
end $$;

drop trigger if exists trg_audit_reaches on public.reaches;
create trigger trg_audit_reaches after insert or update or delete on public.reaches for each row execute function public.write_audit();
drop trigger if exists trg_audit_field_records on public.field_records;
create trigger trg_audit_field_records after insert or update or delete on public.field_records for each row execute function public.write_audit();
drop trigger if exists trg_audit_verifications on public.verifications;
create trigger trg_audit_verifications after insert or update or delete on public.verifications for each row execute function public.write_audit();
drop trigger if exists trg_audit_staff on public.staff_profiles;
create trigger trg_audit_staff after insert or update or delete on public.staff_profiles for each row execute function public.write_audit();

insert into storage.buckets(id,name,public) values('field-evidence','field-evidence',true)
on conflict(id) do update set public=true;

drop policy if exists "public read field evidence" on storage.objects;
create policy "public read field evidence" on storage.objects for select to anon,authenticated
using(bucket_id='field-evidence');

drop policy if exists "approved staff upload field evidence" on storage.objects;
create policy "approved staff upload field evidence" on storage.objects for insert to authenticated
with check(bucket_id='field-evidence' and public.is_approved_staff());

drop policy if exists "approved staff update field evidence" on storage.objects;
create policy "approved staff update field evidence" on storage.objects for update to authenticated
using(bucket_id='field-evidence' and public.is_approved_staff())
with check(bucket_id='field-evidence' and public.is_approved_staff());


create table if not exists public.field_photos (
  id uuid primary key default gen_random_uuid(),
  field_record_id uuid not null references public.field_records(id) on delete cascade,
  photo_type text not null check (photo_type in ('BEFORE','DURING','AFTER')),
  storage_path text not null,
  caption text,
  uploaded_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
alter table public.field_photos enable row level security;
drop policy if exists "public can read field photos" on public.field_photos;
create policy "public can read field photos" on public.field_photos for select to anon,authenticated using(true);
drop policy if exists "approved staff can insert field photos" on public.field_photos;
create policy "approved staff can insert field photos" on public.field_photos for insert to authenticated with check(public.is_approved_staff());
drop trigger if exists trg_audit_field_photos on public.field_photos;
create trigger trg_audit_field_photos after insert or update or delete on public.field_photos for each row execute function public.write_audit();
