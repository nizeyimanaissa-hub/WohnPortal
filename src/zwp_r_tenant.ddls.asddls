@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tenant'
define root view entity ZWP_R_Tenant
  as select from zwp_tenant
{
  key tenant_uuid                                   as TenantUUID,
      tenant_id                                     as TenantID,
      first_name                                    as FirstName,
      last_name                                     as LastName,
      concat_with_space( first_name, last_name, 1 ) as FullName,
      email                                         as Email,
      phone                                         as Phone,
      preferred_language                            as PreferredLanguage,
      app_user                                      as AppUser,
      @Semantics.user.createdBy: true
      created_by                                    as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                                    as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by                         as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                         as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                               as LastChangedAt
}
