@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Maintenance request status log'
define view entity ZWP_R_ReqStatus
  as select from zwp_requ_status
  association        to parent ZWP_R_MaintRequest as _Request       on $projection.RequestUUID = _Request.RequestUUID
  association [0..1] to ZWP_I_ReqStatusVH         as _OldStatusText on $projection.OldStatus = _OldStatusText.Status
  association [0..1] to ZWP_I_ReqStatusVH         as _NewStatusText on $projection.NewStatus = _NewStatusText.Status
  association [0..*] to ZWP_I_UserRole as _MyRoles on _MyRoles.UserID = $session.user
{
  key log_uuid               as LogUUID,
      request_uuid           as RequestUUID,
      _Request.TenantAppUser as TenantAppUser,
      old_status             as OldStatus,
      new_status             as NewStatus,
      changed_by             as ChangedBy,
      changed_at             as ChangedAt,
      note                   as Note,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at  as LocalLastChangedAt,

      _Request,
      _OldStatusText,
      _NewStatusText,
      _MyRoles
}
