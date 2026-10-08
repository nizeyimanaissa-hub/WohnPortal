@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Maintenance request'
define root view entity ZWP_R_MaintRequest
  as select from zwp_maint_req
  composition [0..*] of ZWP_R_ReqStatus   as _StatusLog
  association [1..1] to ZWP_R_Apartment   as _Apartment    on $projection.ApartmentUUID = _Apartment.ApartmentUUID
  association [1..1] to ZWP_R_Tenant      as _Tenant       on $projection.TenantUUID = _Tenant.TenantUUID
  association [0..1] to ZWP_R_Technician  as _Technician   on $projection.TechnicianUUID = _Technician.TechnicianUUID
  association [0..1] to ZWP_I_CategoryVH  as _CategoryText on $projection.Category = _CategoryText.Category
  association [0..1] to ZWP_I_ReqStatusVH as _StatusText   on $projection.Status = _StatusText.Status
{
  key request_uuid          as RequestUUID,
      request_id            as RequestID,
      apartment_uuid        as ApartmentUUID,
      tenant_uuid           as TenantUUID,
      technician_uuid       as TechnicianUUID,
      category              as Category,
      priority              as Priority,
      case priority
        when 1 then 1   -- red
        when 2 then 2   -- orange
        else 0          -- neutral
      end                   as PriorityCriticality,
      title                 as Title,
      description           as Description,
      status                as Status,
      case status
        when 'C' then 3
        when 'R' then 1
        when 'A' then 0
        else 2
      end                   as StatusCriticality,
      reported_at           as ReportedAt,
      due_at                as DueAt,
      planned_date          as PlannedDate,
      completed_at          as CompletedAt,
      resolution_note       as ResolutionNote,
      @Semantics.largeObject: { mimeType: 'MimeType', fileName: 'FileName', contentDispositionPreference: #INLINE }
      attachment            as Attachment,
      @Semantics.mimeType: true
      mime_type             as MimeType,
      file_name             as FileName,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _StatusLog,
      _Apartment,
      _Tenant,
      _Technician,
      _CategoryText,
      _StatusText
}
