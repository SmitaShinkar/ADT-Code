@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view of subcon Sync'
@AbapCatalog.viewEnhancementCategory: [ #PROJECTION_LIST ]
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

/*+[hideWarning] { "IDS" : [ "KEY_CHECK" ]  } */
define root view entity ZI_SUB_SYNC 
 as select from I_MaterialDocumentItem_2 as mItem
 association [1..1] to I_MaterialDocumentHeader_2 as mHead on  $projection.MaterialDocument     = mHead.MaterialDocument
                                                           and $projection.MaterialDocumentYear = mHead.MaterialDocumentYear
 association [1..1] to I_BillingDocumentItem      as bItem on  bItem.ReferenceSDDocument        = $projection.MaterialDocument
{
  key mItem.MaterialDocument,
  key mItem.MaterialDocumentYear,
      mItem.MaterialDocumentItem,
      mItem.GoodsMovementType,
      mItem.Material,
      mHead.MaterialDocumentHeaderText,
      mItem.Plant,
      mItem.StorageLocation,
      mItem.Batch,
      mItem.InventoryStockType,
      mItem.InventorySpecialStockType,
      mItem.Supplier,
      mItem.Customer,
      mItem.CompanyCodeCurrency,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      mItem.TotalGoodsMvtAmtInCCCrcy,
      mItem.MaterialBaseUnit,
      @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'
      mItem.QuantityInBaseUnit,
      mItem.EntryUnit,
      @Semantics.quantity.unitOfMeasure: 'EntryUnit'
      mItem.QuantityInEntryUnit,
      mItem.PurchaseOrder,
      mItem.PurchaseOrderItem,
      mHead.ReferenceDocument,
      mItem.ReversedMaterialDocument,
      mItem.ReversedMaterialDocumentYear,
      mItem.CompanyCode,
      mItem.DeliveryDocument,
      mItem.DeliveryDocumentItem,
      mHead.InventoryTransactionType,
      mItem.ReservationItem,
      mHead.AccountingDocumentType,
      mItem.DocumentDate,
      mItem.PostingDate,
      mItem.DebitCreditCode,
      mHead.CreatedByUser,
      mHead.CreationDate,
      mHead.CreationTime,
      mHead.BillOfLading,
      mHead.VersionForPrintingSlip,
      mHead.ManualPrintIsTriggered,
      mHead.CtrlPostgForExtWhseMgmtSyst,
      bItem.BillingDocument,
      bItem.BillingDocumentItem,
      bItem.BillingQuantityUnit,      
      @Semantics.quantity.unitOfMeasure: 'BillingQuantityUnit'
      bItem.BillingQuantity,
      bItem.BillingDocumentItemText,
      
      /* Associations */
      mHead
}
where mItem.GoodsMovementType        = '541'
  or  mItem.GoodsMovementType        = '542'
  or  mItem.GoodsMovementType        = '543'
  or  mItem.GoodsMovementType        = '544'  
  
