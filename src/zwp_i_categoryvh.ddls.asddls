@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Category value help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZWP_I_CategoryVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZWP_D_CATEGORY' )
{
      @ObjectModel.text.element: [ 'CategoryText' ]
  key value_low as Category,
      @Semantics.text: true
      text      as CategoryText
}
where language = $session.system_language
