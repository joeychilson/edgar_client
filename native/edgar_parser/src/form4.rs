use quick_xml::de::from_str;
use rustler::NifMap;
use serde::Deserialize;

#[derive(Debug, Deserialize, NifMap)]
pub struct Document {
    #[serde(rename = "documentType")]
    document_type: String,
    #[serde(rename = "periodOfReport")]
    period_of_report: String,
    issuer: Issuer,
    #[serde(rename = "reportingOwner")]
    reporting_owner: ReportingOwner,
    #[serde(rename = "nonDerivativeTable")]
    non_derivative_table: Option<NonDerivativeTable>,
    #[serde(rename = "derivativeTable")]
    derivative_table: Option<DerivativeTable>,
    #[serde(rename = "remarks")]
    remarks: Option<String>,
    #[serde(rename = "ownerSignature")]
    owner_signature: OwnerSignature,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Issuer {
    #[serde(rename = "issuerCik")]
    cik: String,
    #[serde(rename = "issuerName")]
    name: String,
    #[serde(rename = "issuerTradingSymbol")]
    trading_symbol: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct ReportingOwner {
    #[serde(rename = "reportingOwnerId")]
    id: ReportingOwnerID,
    #[serde(rename = "reportingOwnerAddress")]
    address: ReportingOwnerAddress,
    #[serde(rename = "reportingOwnerRelationship")]
    relationship: ReportingOwnerRelationship,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct ReportingOwnerID {
    #[serde(rename = "rptOwnerCik")]
    cik: String,
    #[serde(rename = "rptOwnerName")]
    name: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct ReportingOwnerAddress {
    #[serde(rename = "rptOwnerStreet1")]
    street_1: String,
    #[serde(rename = "rptOwnerStreet2")]
    street_2: Option<String>,
    #[serde(rename = "rptOwnerCity")]
    city: String,
    #[serde(rename = "rptOwnerState")]
    state: String,
    #[serde(rename = "rptOwnerZipCode")]
    zip_code: String,
    #[serde(rename = "rptOwnerStateDescription")]
    state_description: Option<String>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct ReportingOwnerRelationship {
    #[serde(rename = "isDirector")]
    is_director: bool,
    #[serde(rename = "isOfficer")]
    is_officer: bool,
    #[serde(rename = "isTenPercentOwner")]
    is_ten_percent_owner: bool,
    #[serde(rename = "isOther")]
    is_other: bool,
    #[serde(rename = "officerTitle")]
    officer_title: Option<String>,
    #[serde(rename = "otherText")]
    other_text: Option<String>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct NonDerivativeTable {
    #[serde(rename = "nonDerivativeTransaction")]
    pub transactions: Option<Vec<Transaction>>,
    #[serde(rename = "nonDerivativeHolding")]
    pub holdings: Option<Vec<Holding>>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct DerivativeTable {
    #[serde(rename = "derivativeTransaction")]
    pub transactions: Option<Vec<Transaction>>,
    #[serde(rename = "derivativeHolding")]
    pub holdings: Option<Vec<Holding>>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Transaction {
    #[serde(rename = "securityTitle")]
    pub security_title: Value,
    #[serde(rename = "conversionOrExercisePrice")]
    pub conversion_or_exercise_price: Option<Value>,
    #[serde(rename = "transactionDate")]
    pub date: Value,
    #[serde(rename = "deemedExecutionDate")]
    pub deemed_execution_date: Option<Value>,
    #[serde(rename = "transactionCoding")]
    pub coding: TransactionCoding,
    #[serde(rename = "transactionAmounts")]
    pub amounts: TransactionAmounts,
    #[serde(rename = "exerciseDate")]
    pub exercise_date: Option<Value>,
    #[serde(rename = "expirationDate")]
    pub expiration_date: Option<Value>,
    #[serde(rename = "underlyingSecurity")]
    pub underlying_security: Option<UnderlyingSecurity>,
    #[serde(rename = "postTransactionAmounts")]
    pub post_transaction_amounts: PostTransactionAmounts,
    #[serde(rename = "ownershipNature")]
    pub ownership_nature: OwnershipNature,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Holding {
    #[serde(rename = "securityTitle")]
    pub security_title: Value,
    #[serde(rename = "conversionOrExercisePrice")]
    pub conversion_or_exercise_price: Option<Value>,
    #[serde(rename = "exerciseDate")]
    pub exercise_date: Option<Value>,
    #[serde(rename = "expirationDate")]
    pub expiration_date: Option<Value>,
    #[serde(rename = "underlyingSecurity")]
    pub underlying_security: Option<UnderlyingSecurity>,
    #[serde(rename = "postTransactionAmounts")]
    pub post_transaction_amounts: PostTransactionAmounts,
    #[serde(rename = "ownershipNature")]
    pub ownership_nature: OwnershipNature,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Value {
    #[serde(rename = "value")]
    value: Option<String>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct TransactionCoding {
    #[serde(rename = "transactionFormType")]
    pub form_type: String,
    #[serde(rename = "transactionCode")]
    pub code: String,
    #[serde(rename = "equitySwapInvolved")]
    pub equity_swap_involved: bool,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct TransactionAmounts {
    #[serde(rename = "transactionShares")]
    pub shares: Value,
    #[serde(rename = "transactionPricePerShare")]
    pub price_per_share: Value,
    #[serde(rename = "transactionAcquiredDisposedCode")]
    pub acquired_disposed_code: Value,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct UnderlyingSecurity {
    #[serde(rename = "underlyingSecurityTitle")]
    pub title: Value,
    #[serde(rename = "underlyingSecurityShares")]
    pub shares: Value,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct PostTransactionAmounts {
    #[serde(rename = "sharesOwnedFollowingTransaction")]
    pub shares_owned_following_transaction: Value,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct OwnershipNature {
    #[serde(rename = "directOrIndirectOwnership")]
    pub direct_or_indirect_ownership: Value,
    #[serde(rename = "natureOfOwnership")]
    pub nature_of_ownership: Option<Value>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct OwnerSignature {
    #[serde(rename = "signatureName")]
    pub name: String,
    #[serde(rename = "signatureDate")]
    pub date: String,
}

#[rustler::nif]
pub fn parse_form4(xml: &str) -> Result<Document, String> {
    let document: Document = from_str::<Document>(xml).map_err(|e| e.to_string())?;
    Ok(document)
}
