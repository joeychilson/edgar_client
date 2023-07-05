use quick_xml::de::from_str;
use rustler::NifStruct;
use serde::Deserialize;

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.Document"]
pub struct Document {
    #[serde(rename = "documentType")]
    document_type: String,
    #[serde(rename = "periodOfReport")]
    period_of_report: String,
    issuer: Issuer,
    #[serde(rename = "reportingOwner")]
    reporting_owner: ReportingOwner,
    #[serde(rename = "nonDerivativeTable")]
    pub non_derivative_table: NonDerivativeTable,
    #[serde(rename = "derivativeTable")]
    pub derivative_table: DerivativeTable,
    #[serde(rename = "remarks")]
    pub remarks: String,
    #[serde(rename = "ownerSignature")]
    pub owner_signature: OwnerSignature,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.Issuer"]
pub struct Issuer {
    #[serde(rename = "issuerCik")]
    cik: String,
    #[serde(rename = "issuerName")]
    name: String,
    #[serde(rename = "issuerTradingSymbol")]
    trading_symbol: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.ReportingOwner"]
pub struct ReportingOwner {
    #[serde(rename = "reportingOwnerId")]
    id: ReportingOwnerID,
    #[serde(rename = "reportingOwnerAddress")]
    address: ReportingOwnerAddress,
    #[serde(rename = "reportingOwnerRelationship")]
    relationship: ReportingOwnerRelationship,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.ReportingOwnerID"]
pub struct ReportingOwnerID {
    #[serde(rename = "rptOwnerCik")]
    cik: String,
    #[serde(rename = "rptOwnerName")]
    name: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.ReportingOwnerAddress"]
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

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.ReportingOwnerRelationship"]
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

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.NonDerivativeTable"]
pub struct NonDerivativeTable {
    #[serde(rename = "nonDerivativeTransaction")]
    pub transactions: Option<Vec<Transaction>>,
    #[serde(rename = "nonDerivativeHolding")]
    pub holdings: Option<Vec<Holding>>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.DerivativeTable"]
pub struct DerivativeTable {
    #[serde(rename = "derivativeTransaction")]
    pub transactions: Option<Vec<Transaction>>,
    #[serde(rename = "derivativeHolding")]
    pub holdings: Option<Vec<Holding>>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.Transaction"]
pub struct Transaction {
    #[serde(rename = "securityTitle")]
    pub security_title: StringValue,
    #[serde(rename = "conversionOrExercisePrice")]
    pub conversion_or_exercise_price: Option<StringValue>,
    #[serde(rename = "transactionDate")]
    pub date: StringValue,
    #[serde(rename = "deemedExecutionDate")]
    pub deemed_execution_date: Option<StringValue>,
    #[serde(rename = "transactionCoding")]
    pub coding: TransactionCoding,
    #[serde(rename = "transactionAmounts")]
    pub amounts: TransactionAmounts,
    #[serde(rename = "exerciseDate")]
    pub exercise_date: Option<StringValue>,
    #[serde(rename = "expirationDate")]
    pub expiration_date: Option<StringValue>,
    #[serde(rename = "underlyingSecurity")]
    pub underlying_security: Option<UnderlyingSecurity>,
    #[serde(rename = "postTransactionAmounts")]
    pub post_transaction_amounts: PostTransactionAmounts,
    #[serde(rename = "ownershipNature")]
    pub ownership_nature: OwnershipNature,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.Holding"]
pub struct Holding {
    #[serde(rename = "securityTitle")]
    pub security_title: StringValue,
    #[serde(rename = "conversionOrExercisePrice")]
    pub conversion_or_exercise_price: Option<FloatValue>,
    #[serde(rename = "exerciseDate")]
    pub exercise_date: Option<StringValue>,
    #[serde(rename = "expirationDate")]
    pub expiration_date: Option<StringValue>,
    #[serde(rename = "underlyingSecurity")]
    pub underlying_security: Option<UnderlyingSecurity>,
    #[serde(rename = "postTransactionAmounts")]
    pub post_transaction_amounts: PostTransactionAmounts,
    #[serde(rename = "ownershipNature")]
    pub ownership_nature: OwnershipNature,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.StringValue"]
pub struct StringValue {
    #[serde(rename = "value")]
    value: Option<String>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.IntValue"]
pub struct IntValue {
    #[serde(rename = "value")]
    value: Option<i32>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.FloatValue"]
pub struct FloatValue {
    #[serde(rename = "value")]
    value: Option<f32>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.TransactionCoding"]
pub struct TransactionCoding {
    #[serde(rename = "transactionFormType")]
    pub form_type: String,
    #[serde(rename = "transactionCode")]
    pub code: String,
    #[serde(rename = "equitySwapInvolved")]
    pub equity_swap_involved: bool,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.TransactionAmounts"]
pub struct TransactionAmounts {
    #[serde(rename = "transactionShares")]
    pub shares: IntValue,
    #[serde(rename = "transactionPricePerShare")]
    pub price_per_share: FloatValue,
    #[serde(rename = "transactionAcquiredDisposedCode")]
    pub acquired_disposed_code: StringValue,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.UnderlyingSecurity"]
pub struct UnderlyingSecurity {
    #[serde(rename = "underlyingSecurityTitle")]
    pub title: StringValue,
    #[serde(rename = "underlyingSecurityShares")]
    pub shares: FloatValue,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.PostTransactionAmounts"]
pub struct PostTransactionAmounts {
    #[serde(rename = "sharesOwnedFollowingTransaction")]
    pub shares_owned_following_transaction: IntValue,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.OwnershipNature"]
pub struct OwnershipNature {
    #[serde(rename = "directOrIndirectOwnership")]
    pub direct_or_indirect_ownership: StringValue,
    #[serde(rename = "natureOfOwnership")]
    pub nature_of_ownership: Option<StringValue>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form4.OwnerSignature"]
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
