@EndUserText.label: 'Projection view of Subcon'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZC_SUB_SYNC 
 provider contract transactional_query 
as projection on ZI_SUB_SYNC
{
    key MaterialDocument,
    key MaterialDocumentYear,
    MaterialDocumentItem,
    GoodsMovementType,
    Material,
    MaterialDocumentHeaderText,
    Plant,
    StorageLocation,
    Batch,
    InventoryStockType,
    InventorySpecialStockType,
    Supplier,
    Customer,
    CompanyCodeCurrency,
    @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
    TotalGoodsMvtAmtInCCCrcy,
    MaterialBaseUnit,
    @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'    
    QuantityInBaseUnit,
    EntryUnit,
    @Semantics.quantity.unitOfMeasure: 'MaterialBaseUnit'    
    QuantityInEntryUnit,
    PurchaseOrder,
    PurchaseOrderItem,
    ReferenceDocument,
    ReversedMaterialDocument,
    ReversedMaterialDocumentYear,
    CompanyCode,
    DeliveryDocument,
    DeliveryDocumentItem,
    InventoryTransactionType,
    ReservationItem,
    AccountingDocumentType,
    DocumentDate,
    PostingDate,
    DebitCreditCode,
    CreatedByUser,
    CreationDate,
    CreationTime,
    BillOfLading,
    VersionForPrintingSlip,
    ManualPrintIsTriggered,
    CtrlPostgForExtWhseMgmtSyst,
    BillingDocument,
    BillingDocumentItem,
    BillingQuantityUnit,
    @Semantics.quantity.unitOfMeasure: 'BillingQuantityUnit'      
    BillingQuantity,
    BillingDocumentItemText,
    /* Associations */
    mHead
}
