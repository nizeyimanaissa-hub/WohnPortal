@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Technician'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZWP_R_Technician
  as select from zwp_technician
{
  key technician_uuid       as TechnicianUUID,
      technician_id         as TechnicianID,
      full_name             as FullName,
      phone                 as Phone,
      trade                 as Trade,
      city                  as City,
      is_active             as IsActive,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt
}
