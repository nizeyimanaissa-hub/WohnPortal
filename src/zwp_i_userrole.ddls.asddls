@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'WohnPortal user roles'
define view entity ZWP_I_UserRole
  as select from zwp_user_role
{
  key user_id as UserID,
  key role    as Role
}
