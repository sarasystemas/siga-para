-- Base inicial para equipes municipais com registros compartilhados por tenant.
-- O frontend atual ainda não consome estas tabelas; veja README.md antes de usar.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  created_at timestamptz not null default now()
);

create table public.tenant_members (
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'user')),
  created_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create or replace function private.is_tenant_member(target_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.tenant_members as membership
    where membership.tenant_id = target_tenant_id
      and membership.user_id = (select auth.uid())
  );
$$;

revoke all on function private.is_tenant_member(uuid) from public, anon;
grant execute on function private.is_tenant_member(uuid) to authenticated;

create table public.communities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 160),
  created_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, name)
);

create table public.technicians (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  full_name text not null check (length(trim(full_name)) between 1 and 160),
  function_title text not null default '',
  registration text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 180),
  organization_type text not null default '',
  president text not null default '',
  member_count integer not null default 0 check (member_count >= 0),
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.farmers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  community_id uuid,
  organization_id uuid,
  full_name text not null check (length(trim(full_name)) between 1 and 180),
  cpf text not null,
  rg text not null default '',
  nis text not null default '',
  caf_number text not null default '',
  caf_valid boolean not null default false,
  birth_date date,
  sex text not null default '',
  marital_status text not null default '',
  phone text not null default '',
  whatsapp text not null default '',
  email text not null default '',
  ramal text not null default '',
  neighborhood text not null default '',
  street text not null default '',
  address_number text not null default '',
  gps_coordinates text not null default '',
  main_crop text not null default '',
  area_hectares numeric(12, 2) not null default 0 check (area_hectares >= 0),
  production_tons_year numeric(12, 2) not null default 0 check (production_tons_year >= 0),
  production_type text not null default '',
  family_farming boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, cpf),
  foreign key (tenant_id, community_id) references public.communities(tenant_id, id),
  foreign key (tenant_id, organization_id) references public.organizations(tenant_id, id)
);

create table public.fleet_assets (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 180),
  category text not null default '',
  identifier text not null default '',
  status text not null default '',
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  farmer_id uuid not null,
  technician_id uuid not null,
  protocol_number text not null,
  service text not null check (length(trim(service)) between 1 and 180),
  scheduled_at timestamptz not null,
  status text not null default 'Agendado'
    check (status in ('Agendado', 'Confirmado', 'Em Atendimento', 'Concluído', 'Cancelado', 'Não Compareceu')),
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, protocol_number),
  foreign key (tenant_id, farmer_id) references public.farmers(tenant_id, id),
  foreign key (tenant_id, technician_id) references public.technicians(tenant_id, id)
);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  record_label text not null default '',
  event_type text not null default '',
  created_at timestamptz not null default now()
);

create index tenant_members_user_id_idx
  on public.tenant_members(user_id, tenant_id);
create index technicians_tenant_name_idx
  on public.technicians(tenant_id, full_name);
create index organizations_tenant_name_idx
  on public.organizations(tenant_id, name);
create index farmers_tenant_name_idx
  on public.farmers(tenant_id, full_name);
create index farmers_tenant_community_idx
  on public.farmers(tenant_id, community_id);
create index fleet_assets_tenant_name_idx
  on public.fleet_assets(tenant_id, name);
create index appointments_tenant_schedule_idx
  on public.appointments(tenant_id, scheduled_at);
create index appointments_tenant_farmer_idx
  on public.appointments(tenant_id, farmer_id, scheduled_at);
create index audit_logs_tenant_created_idx
  on public.audit_logs(tenant_id, created_at desc);

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger farmers_touch_updated_at
  before update on public.farmers
  for each row execute function private.touch_updated_at();

create trigger appointments_touch_updated_at
  before update on public.appointments
  for each row execute function private.touch_updated_at();

alter table public.tenants enable row level security;
alter table public.tenant_members enable row level security;
create policy tenant_members_select_self
  on public.tenant_members for select to authenticated
  using (user_id = (select auth.uid()));
create policy tenants_select_member
  on public.tenants for select to authenticated
  using (private.is_tenant_member(id));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'communities',
    'technicians',
    'organizations',
    'farmers',
    'fleet_assets',
    'appointments'
  ]
  loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format(
      'create policy tenant_team_select on public.%I for select to authenticated using (private.is_tenant_member(tenant_id))',
      table_name
    );
    execute format(
      'create policy tenant_team_insert on public.%I for insert to authenticated with check (private.is_tenant_member(tenant_id))',
      table_name
    );
    execute format(
      'create policy tenant_team_update on public.%I for update to authenticated using (private.is_tenant_member(tenant_id)) with check (private.is_tenant_member(tenant_id))',
      table_name
    );
    execute format(
      'create policy tenant_team_delete on public.%I for delete to authenticated using (private.is_tenant_member(tenant_id))',
      table_name
    );
  end loop;
end
$$;

alter table public.audit_logs enable row level security;
create policy audit_logs_select_member
  on public.audit_logs for select to authenticated
  using (private.is_tenant_member(tenant_id));
create policy audit_logs_insert_actor
  on public.audit_logs for insert to authenticated
  with check (
    private.is_tenant_member(tenant_id)
    and actor_id = (select auth.uid())
  );

grant select on public.tenants, public.tenant_members to authenticated;
grant select, insert, update, delete
  on public.communities, public.technicians, public.organizations,
     public.farmers, public.fleet_assets, public.appointments
  to authenticated;
grant select, insert on public.audit_logs to authenticated;
