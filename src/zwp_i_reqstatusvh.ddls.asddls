@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Request status value help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZWP_I_ReqStatusVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZWP_D_REQ_STATUS' )
{
      @ObjectModel.text.element: [ 'StatusText' ]
  key value_low as Status,
      @Semantics.text: true
      text      as StatusText
}
where language = $session.system_language
