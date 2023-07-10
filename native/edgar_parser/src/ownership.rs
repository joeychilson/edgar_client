use crate::{get_bool, get_string, parse_value, Value};
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

// https://www.sec.gov/info/edgar/specifications/ownershipxmltechspec

#[derive(NifMap)]
pub struct Document {
    schema_version: Option<String>,
    document_type: Option<String>,
    period_of_report: Option<String>,
    date_of_original_submission: Option<String>,
    no_securities_owned: Option<bool>,
    not_subject_to_section_16: Option<bool>,
    form3_holdings_reported: Option<bool>,
    form4_transactions_reported: Option<bool>,
    issuer: Option<Issuer>,
    reporting_owner: Option<ReportingOwner>,
    aff10b5_one: Option<bool>,
    non_derivative_table: Option<NonDerivativeTable>,
    derivative_table: Option<DerivativeTable>,
    footnotes: Vec<Footnote>,
    remarks: Option<String>,
    owner_signature: Option<OwnerSignature>,
}

#[derive(NifMap)]
pub struct Issuer {
    cik: Option<String>,
    name: Option<String>,
    trading_symbol: Option<String>,
}

#[derive(NifMap)]
pub struct ReportingOwner {
    id: Option<ReportingOwnerID>,
    address: Option<ReportingOwnerAddress>,
    relationship: Option<ReportingOwnerRelationship>,
}

#[derive(NifMap)]
pub struct ReportingOwnerID {
    cik: Option<String>,
    ccc: Option<String>,
    name: Option<String>,
}

#[derive(NifMap)]
pub struct ReportingOwnerAddress {
    street1: Option<String>,
    street2: Option<String>,
    city: Option<String>,
    state: Option<String>,
    zip_code: Option<String>,
    state_description: Option<String>,
}

#[derive(NifMap)]
pub struct ReportingOwnerRelationship {
    is_director: Option<bool>,
    is_officer: Option<bool>,
    is_ten_percent_owner: Option<bool>,
    is_other: Option<bool>,
    officer_title: Option<String>,
    other_text: Option<String>,
}

#[derive(NifMap)]
pub struct NonDerivativeTable {
    transactions: Vec<NonDerivativeTransaction>,
    holdings: Vec<NonDerivativeHolding>,
}

#[derive(NifMap)]
pub struct DerivativeTable {
    transactions: Vec<DerivativeTransaction>,
    holdings: Vec<DerivativeHolding>,
}

#[derive(NifMap)]
pub struct NonDerivativeTransaction {
    security_title: Option<ValueFootnote>,
    transaction_date: Option<ValueFootnote>,
    deemed_execution_date: Option<ValueFootnote>,
    transaction_coding: Option<TransactionCoding>,
    transaction_timeliness: Option<ValueFootnote>,
    transaction_amounts: Option<TransactionAmounts>,
    post_transaction_amounts: Option<PostTransactionAmounts>,
    ownership_nature: Option<OwnershipNature>,
}

#[derive(NifMap)]
pub struct DerivativeTransaction {
    security_title: Option<ValueFootnote>,
    conversion_or_exercise_price: Option<ValueFootnote>,
    deemed_execution_date: Option<ValueFootnote>,
    transaction_coding: Option<TransactionCoding>,
    transaction_timeliness: Option<ValueFootnote>,
    transaction_amounts: Option<DerivativeTransactionAmounts>,
    exercise_date: Option<ValueFootnote>,
    expiration_date: Option<ValueFootnote>,
    underlying_security: Option<UnderlyingSecurity>,
    post_transaction_amounts: Option<PostTransactionAmounts>,
    ownership_nature: Option<OwnershipNature>,
}

#[derive(NifMap)]
pub struct NonDerivativeHolding {
    security_title: Option<ValueFootnote>,
    transaction_coding: Option<HoldingCoding>,
    post_transaction_amounts: Option<PostTransactionAmounts>,
    ownership_nature: Option<OwnershipNature>,
}

#[derive(NifMap)]
pub struct DerivativeHolding {
    security_title: Option<ValueFootnote>,
    conversion_or_exercise_price: Option<ValueFootnote>,
    transaction_coding: Option<HoldingCoding>,
    exercise_date: Option<ValueFootnote>,
    expiration_date: Option<ValueFootnote>,
    underlying_security: Option<UnderlyingSecurity>,
    post_transaction_amounts: Option<PostTransactionAmounts>,
    ownership_nature: Option<OwnershipNature>,
}

#[derive(NifMap)]
pub struct TransactionCoding {
    form_type: Option<String>,
    transaction_code: Option<String>,
    equity_swap_involved: Option<bool>,
    footnote_id: Option<String>,
}

#[derive(NifMap)]
pub struct HoldingCoding {
    form_type: Option<String>,
    footnote_id: Option<String>,
}

#[derive(NifMap)]
pub struct TransactionAmounts {
    shares: Option<ValueFootnote>,
    price_per_share: Option<ValueFootnote>,
    acquired_disposed_code: Option<ValueFootnote>,
}

#[derive(NifMap)]
pub struct DerivativeTransactionAmounts {
    shares: Option<ValueFootnote>,
    price_per_share: Option<ValueFootnote>,
    total_value: Option<ValueFootnote>,
    acquired_disposed_code: Option<ValueFootnote>,
}

#[derive(NifMap)]
pub struct UnderlyingSecurity {
    title: Option<ValueFootnote>,
    shares: Option<ValueFootnote>,
    value: Option<ValueFootnote>,
}

#[derive(NifMap)]
pub struct PostTransactionAmounts {
    shares_owned_following_transaction: Option<ValueFootnote>,
    value_owned_following_transaction: Option<ValueFootnote>,
}

#[derive(NifMap)]
pub struct OwnershipNature {
    direct_or_indirect_ownership: Option<ValueFootnote>,
    nature_of_ownership: Option<ValueFootnote>,
}

#[derive(NifMap)]
pub struct Footnote {
    id: Option<String>,
    note: Option<String>,
}

#[derive(NifMap)]
pub struct OwnerSignature {
    name: Option<String>,
    date: Option<String>,
}

#[derive(NifMap)]
pub struct ValueFootnote {
    value: Option<Value>,
    footnote_id: Option<String>,
}

#[rustler::nif]
pub fn parse_ownership_form(xml: &str) -> Result<Document, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();

    let schema_version = get_string(&root_node, "schemaVersion");
    let document_type = get_string(&root_node, "documentType");
    let period_of_report = get_string(&root_node, "periodOfReport");
    let date_of_original_submission = get_string(&root_node, "dateOfOriginalSubmission");
    let no_securities_owned = get_bool(&root_node, "noSecuritiesOwned");
    let not_subject_to_section_16 = get_bool(&root_node, "notSubjectToSection16");
    let form3_holdings_reported = get_bool(&root_node, "form3HoldingsReported");
    let form4_transactions_reported = get_bool(&root_node, "form4TransactionsReported");

    let issuer = parse_issuer(&root_node)?;
    let reporting_owner = parse_reporting_owner(&root_node)?;

    let aff10b5_one = get_bool(&root_node, "aff10b5One");

    let non_derivative_table = parse_non_derivative_table(&root_node)?;
    let derivative_table = parse_derivative_table(&root_node)?;

    let footnotes = parse_footnotes(&root_node)?;
    let remarks = get_string(&root_node, "remarks");
    let owner_signature = parse_owner_signature(&root_node)?;

    Ok(Document {
        schema_version,
        document_type,
        period_of_report,
        date_of_original_submission,
        no_securities_owned,
        not_subject_to_section_16,
        form3_holdings_reported,
        form4_transactions_reported,
        issuer,
        reporting_owner,
        aff10b5_one,
        non_derivative_table,
        derivative_table,
        footnotes,
        remarks,
        owner_signature,
    })
}

fn parse_issuer(node: &roxmltree::Node) -> Result<Option<Issuer>, String> {
    node.children()
        .find(|node| node.has_tag_name("issuer"))
        .map(|issuer_node| {
            let cik = get_string(&issuer_node, "issuerCik");
            let name = get_string(&issuer_node, "issuerName");
            let trading_symbol = get_string(&issuer_node, "issuerTradingSymbol");

            Ok(Issuer {
                cik,
                name,
                trading_symbol,
            })
        })
        .transpose()
}

fn parse_reporting_owner(node: &roxmltree::Node) -> Result<Option<ReportingOwner>, String> {
    node.children()
        .find(|node| node.has_tag_name("reportingOwner"))
        .map(|owner_node| {
            let id = parse_reporting_owner_id(&owner_node)?;
            let address = parse_reporting_owner_address(&owner_node)?;
            let relationship = parse_reporting_owner_relationship(&owner_node)?;

            Ok(ReportingOwner {
                id,
                address,
                relationship,
            })
        })
        .transpose()
}

fn parse_reporting_owner_id(node: &roxmltree::Node) -> Result<Option<ReportingOwnerID>, String> {
    node.children()
        .find(|node| node.has_tag_name("reportingOwnerId"))
        .map(|id_node| {
            let cik = get_string(&id_node, "rptOwnerCik");
            let ccc = get_string(&id_node, "rptOwnerCcc");
            let name = get_string(&id_node, "rptOwnerName");

            Ok(ReportingOwnerID { cik, ccc, name })
        })
        .transpose()
}

fn parse_reporting_owner_address(
    node: &roxmltree::Node,
) -> Result<Option<ReportingOwnerAddress>, String> {
    node.children()
        .find(|node| node.has_tag_name("reportingOwnerAddress"))
        .map(|address_node| {
            let street1 = get_string(&address_node, "rptOwnerStreet1");
            let street2 = get_string(&address_node, "rptOwnerStreet2");
            let city = get_string(&address_node, "rptOwnerCity");
            let state = get_string(&address_node, "rptOwnerState");
            let zip_code = get_string(&address_node, "rptOwnerZipCode");
            let state_description = get_string(&address_node, "rptOwnerStateDescription");

            Ok(ReportingOwnerAddress {
                street1,
                street2,
                city,
                state,
                zip_code,
                state_description,
            })
        })
        .transpose()
}

fn parse_reporting_owner_relationship(
    node: &roxmltree::Node,
) -> Result<Option<ReportingOwnerRelationship>, String> {
    node.children()
        .find(|node| node.has_tag_name("reportingOwnerRelationship"))
        .map(|relationship_node| {
            let is_director = get_bool(&relationship_node, "isDirector");
            let is_officer = get_bool(&relationship_node, "isOfficer");
            let is_ten_percent_owner = get_bool(&relationship_node, "isTenPercentOwner");
            let is_other = get_bool(&relationship_node, "isOther");
            let officer_title = get_string(&relationship_node, "officerTitle");
            let other_text = get_string(&relationship_node, "otherText");

            Ok(ReportingOwnerRelationship {
                is_director,
                is_officer,
                is_ten_percent_owner,
                is_other,
                officer_title,
                other_text,
            })
        })
        .transpose()
}

fn parse_non_derivative_table(
    node: &roxmltree::Node,
) -> Result<Option<NonDerivativeTable>, String> {
    node.children()
        .find(|node| node.has_tag_name("nonDerivativeTable"))
        .map(|table_node| {
            let transactions = parse_non_derivative_transactions(&table_node)?;
            let holdings = parse_non_derivative_holdings(&table_node)?;

            Ok(NonDerivativeTable {
                transactions,
                holdings,
            })
        })
        .transpose()
}

fn parse_derivative_table(node: &roxmltree::Node) -> Result<Option<DerivativeTable>, String> {
    node.children()
        .find(|node| node.has_tag_name("derivativeTable"))
        .map(|table_node| {
            let transactions = parse_derivative_transactions(&table_node)?;
            let holdings = parse_derivative_holdings(&table_node)?;

            Ok(DerivativeTable {
                transactions,
                holdings,
            })
        })
        .transpose()
}

fn parse_non_derivative_transactions(
    node: &roxmltree::Node,
) -> Result<Vec<NonDerivativeTransaction>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("nonDerivativeTransaction"))
        .filter_map(|transaction_node| {
            let security_title = get_value_footnote(&transaction_node, "securityTitle");
            let transaction_date = get_value_footnote(&transaction_node, "transactionDate");
            let deemed_execution_date =
                get_value_footnote(&transaction_node, "deemedExecutionDate");
            let transaction_timeliness = get_value_footnote(&transaction_node, "transactionCoding");
            let transaction_coding = parse_transaction_coding(&transaction_node).ok()?;
            let transaction_amounts = parse_transaction_amounts(&transaction_node).ok()?;
            let post_transaction_amounts =
                parse_post_transaction_amounts(&transaction_node).ok()?;
            let ownership_nature = parse_ownership_nature(&transaction_node).ok()?;

            Some(NonDerivativeTransaction {
                security_title,
                transaction_date,
                deemed_execution_date,
                transaction_timeliness,
                transaction_coding,
                transaction_amounts,
                post_transaction_amounts,
                ownership_nature,
            })
        })
        .collect();
    Ok(transactions)
}

fn parse_derivative_transactions(
    node: &roxmltree::Node,
) -> Result<Vec<DerivativeTransaction>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("derivativeTransaction"))
        .filter_map(|transaction_node| {
            let security_title = get_value_footnote(&transaction_node, "securityTitle");
            let conversion_or_exercise_price =
                get_value_footnote(&transaction_node, "conversionOrExercisePrice");
            let deemed_execution_date =
                get_value_footnote(&transaction_node, "deemedExecutionDate");
            let transaction_coding = parse_transaction_coding(&transaction_node).ok()?;
            let transaction_timeliness =
                get_value_footnote(&transaction_node, "transactionTimeliness");
            let transaction_amounts =
                parse_derivative_transaction_amounts(&transaction_node).ok()?;
            let exercise_date = get_value_footnote(&transaction_node, "exerciseDate");
            let expiration_date = get_value_footnote(&transaction_node, "expirationDate");
            let underlying_security = parse_underlying_security(&transaction_node).ok()?;
            let post_transaction_amounts =
                parse_post_transaction_amounts(&transaction_node).ok()?;
            let ownership_nature = parse_ownership_nature(&transaction_node).ok()?;

            Some(DerivativeTransaction {
                security_title,
                conversion_or_exercise_price,
                deemed_execution_date,
                transaction_coding,
                transaction_timeliness,
                transaction_amounts,
                exercise_date,
                expiration_date,
                underlying_security,
                post_transaction_amounts,
                ownership_nature,
            })
        })
        .collect();
    Ok(transactions)
}

fn parse_non_derivative_holdings(
    node: &roxmltree::Node,
) -> Result<Vec<NonDerivativeHolding>, String> {
    let holdings = node
        .children()
        .filter(|node| node.has_tag_name("nonDerivativeHolding"))
        .filter_map(|holdings_node| {
            let security_title = get_value_footnote(&holdings_node, "securityTitle");
            let transaction_coding = parse_holding_coding(&holdings_node).ok()?;
            let post_transaction_amounts = parse_post_transaction_amounts(&holdings_node).ok()?;
            let ownership_nature = parse_ownership_nature(&holdings_node).ok()?;

            Some(NonDerivativeHolding {
                security_title,
                transaction_coding,
                post_transaction_amounts,
                ownership_nature,
            })
        })
        .collect();
    Ok(holdings)
}

fn parse_derivative_holdings(node: &roxmltree::Node) -> Result<Vec<DerivativeHolding>, String> {
    let holdings = node
        .children()
        .filter(|node| node.has_tag_name("derivativeHolding"))
        .filter_map(|holdings_node| {
            let security_title = get_value_footnote(&holdings_node, "securityTitle");
            let conversion_or_exercise_price =
                get_value_footnote(&holdings_node, "conversionOrExercisePrice");
            let transaction_coding = parse_holding_coding(&holdings_node).ok()?;
            let exercise_date = get_value_footnote(&holdings_node, "exerciseDate");
            let expiration_date = get_value_footnote(&holdings_node, "expirationDate");
            let underlying_security = parse_underlying_security(&holdings_node).ok()?;
            let post_transaction_amounts = parse_post_transaction_amounts(&holdings_node).ok()?;
            let ownership_nature = parse_ownership_nature(&holdings_node).ok()?;

            Some(DerivativeHolding {
                security_title,
                conversion_or_exercise_price,
                transaction_coding,
                exercise_date,
                expiration_date,
                underlying_security,
                post_transaction_amounts,
                ownership_nature,
            })
        })
        .collect();
    Ok(holdings)
}

fn parse_transaction_coding(node: &roxmltree::Node) -> Result<Option<TransactionCoding>, String> {
    node.children()
        .find(|node| node.has_tag_name("transactionCoding"))
        .map(|coding_node| {
            let form_type = get_string(&coding_node, "transactionFormType");
            let transaction_code = get_string(&coding_node, "transactionCode");
            let equity_swap_involved = get_bool(&coding_node, "equitySwapInvolved");
            let footnote_id = get_string(&coding_node, "footnoteId");

            Ok(TransactionCoding {
                form_type,
                transaction_code,
                equity_swap_involved,
                footnote_id,
            })
        })
        .transpose()
}

fn parse_holding_coding(node: &roxmltree::Node) -> Result<Option<HoldingCoding>, String> {
    node.children()
        .find(|node| node.has_tag_name("transactionCoding"))
        .map(|coding_node| {
            let form_type = get_string(&coding_node, "transactionFormType");
            let footnote_id = get_string(&coding_node, "footnoteId");

            Ok(HoldingCoding {
                form_type,
                footnote_id,
            })
        })
        .transpose()
}

fn parse_transaction_amounts(node: &roxmltree::Node) -> Result<Option<TransactionAmounts>, String> {
    node.children()
        .find(|node| node.has_tag_name("transactionAmounts"))
        .map(|amounts_node| {
            let shares = get_value_footnote(&amounts_node, "transactionShares");
            let price_per_share = get_value_footnote(&amounts_node, "transactionPricePerShare");
            let acquired_disposed_code =
                get_value_footnote(&amounts_node, "transactionAcquiredDisposedCode");

            Ok(TransactionAmounts {
                shares,
                price_per_share,
                acquired_disposed_code,
            })
        })
        .transpose()
}

fn parse_derivative_transaction_amounts(
    node: &roxmltree::Node,
) -> Result<Option<DerivativeTransactionAmounts>, String> {
    node.children()
        .find(|node| node.has_tag_name("transactionAmounts"))
        .map(|amounts_node| {
            let shares = get_value_footnote(&amounts_node, "transactionShares");
            let price_per_share = get_value_footnote(&amounts_node, "transactionPricePerShare");
            let total_value = get_value_footnote(&amounts_node, "transactionTotalValue");
            let acquired_disposed_code =
                get_value_footnote(&amounts_node, "transactionAcquiredDisposedCode");

            Ok(DerivativeTransactionAmounts {
                shares,
                price_per_share,
                total_value,
                acquired_disposed_code,
            })
        })
        .transpose()
}

fn parse_underlying_security(node: &roxmltree::Node) -> Result<Option<UnderlyingSecurity>, String> {
    node.children()
        .find(|node| node.has_tag_name("underlyingSecurity"))
        .map(|security_node| {
            let title = get_value_footnote(&security_node, "underlyingSecurityTitle");
            let shares = get_value_footnote(&security_node, "underlyingSecurityShares");
            let value = get_value_footnote(&security_node, "underlyingSecurityValue");

            Ok(UnderlyingSecurity {
                title,
                shares,
                value,
            })
        })
        .transpose()
}

fn parse_post_transaction_amounts(
    node: &roxmltree::Node,
) -> Result<Option<PostTransactionAmounts>, String> {
    node.children()
        .find(|node| node.has_tag_name("postTransactionAmounts"))
        .map(|amounts_node| {
            let shares_owned_following_transaction =
                get_value_footnote(&amounts_node, "sharesOwnedFollowingTransaction");
            let value_owned_following_transaction =
                get_value_footnote(&amounts_node, "valueOwnedFollowingTransaction");

            Ok(PostTransactionAmounts {
                shares_owned_following_transaction,
                value_owned_following_transaction,
            })
        })
        .transpose()
}

fn parse_ownership_nature(node: &roxmltree::Node) -> Result<Option<OwnershipNature>, String> {
    node.children()
        .find(|node| node.has_tag_name("ownershipNature"))
        .map(|nature_node| {
            let direct_or_indirect_ownership =
                get_value_footnote(&nature_node, "directOrIndirectOwnership");
            let nature_of_ownership = get_value_footnote(&nature_node, "natureOfOwnership");

            Ok(OwnershipNature {
                direct_or_indirect_ownership,
                nature_of_ownership,
            })
        })
        .transpose()
}

fn parse_footnotes(node: &roxmltree::Node) -> Result<Vec<Footnote>, String> {
    let footnotes = node
        .children()
        .filter(|node| node.has_tag_name("footnotes"))
        .flat_map(|node| node.children())
        .filter(|node| node.has_tag_name("footnote"))
        .filter_map(|footnote_node| {
            let id = footnote_node.attribute("id").map(|id| id.to_string());
            let note = footnote_node.text().map(|text| text.to_string());

            Some(Footnote { id, note })
        })
        .collect();
    Ok(footnotes)
}

fn parse_owner_signature(node: &roxmltree::Node) -> Result<Option<OwnerSignature>, String> {
    node.children()
        .find(|node| node.has_tag_name("ownerSignature"))
        .map(|signature_node| {
            let name = get_string(&signature_node, "signatureName");
            let date = get_string(&signature_node, "signatureDate");

            Ok(OwnerSignature { name, date })
        })
        .transpose()
}

fn get_value_footnote(node: &roxmltree::Node, tag: &str) -> Option<ValueFootnote> {
    node.children()
        .find(|node| node.has_tag_name(tag))
        .map(|tag_node| {
            let value = tag_node
                .children()
                .find(|child_node| child_node.has_tag_name("value"))
                .and_then(|value_node| value_node.text())
                .map(|s| parse_value(s.to_string()));

            let footnote_id = tag_node
                .children()
                .find(|child_node| child_node.has_tag_name("footnoteId"))
                .and_then(|id_node| id_node.attribute("id"))
                .map(|s| s.to_string());

            ValueFootnote { value, footnote_id }
        })
}
