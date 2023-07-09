use crate::xml::{get_bool, get_string, get_value, Value};
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

#[derive(NifMap)]
pub struct Document {
    schema_version: Option<String>,
    document_type: Option<String>,
    period_of_report: Option<String>,
    issuer: Option<Issuer>,
    reporting_owner: Option<ReportingOwner>,
    non_derivative_table: Option<NonDerivativeTable>,
    derivative_table: Option<DerivativeTable>,
}

#[derive(NifMap)]
pub struct Issuer {
    cik: Option<String>,
    name: Option<String>,
    trading_symbol: Option<String>,
}

#[derive(NifMap)]
pub struct ReportingOwner {
    cik: Option<String>,
    name: Option<String>,
    is_director: Option<bool>,
    is_officer: Option<bool>,
    is_ten_percent_owner: Option<bool>,
    is_other: Option<bool>,
    officer_title: Option<String>,
    address: Option<ReportingOwnerAddress>,
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
pub struct NonDerivativeTable {
    transactions: Vec<NonDerivativeTransaction>,
    holdings: Vec<NonDerivativeHolding>,
}

#[derive(NifMap)]
pub struct NonDerivativeTransaction {
    security_title: Option<Value>,
    date: Option<Value>,
    deemed_execution_date: Option<Value>,
    timeliness: Option<Value>,
    form_type: Option<String>,
    code: Option<String>,
    equity_swap_involved: Option<bool>,
    shares: Option<Value>,
    price_per_share: Option<Value>,
    acquired_disposed_code: Option<Value>,
    shares_owned_following_transaction: Option<Value>,
    direct_or_indirect_ownership: Option<Value>,
}

#[derive(NifMap)]
pub struct NonDerivativeHolding {
    security_title: Option<Value>,
    shares_owned_following_transaction: Option<Value>,
    direct_or_indirect_ownership: Option<Value>,
}

#[derive(NifMap)]
pub struct DerivativeTable {
    transactions: Vec<DerivativeTransaction>,
    holdings: Vec<DerivativeHolding>,
}

#[derive(NifMap)]
pub struct DerivativeTransaction {
    security_title: Option<Value>,
    date: Option<Value>,
    exercise_date: Option<Value>,
    expiration_date: Option<Value>,
    form_type: Option<String>,
    code: Option<String>,
    equity_swap_involved: Option<bool>,
    shares: Option<Value>,
    price_per_share: Option<Value>,
    acquired_disposed_code: Option<Value>,
    underlying_security_title: Option<Value>,
    underlying_security_shares: Option<Value>,
    conversion_or_exercise_price: Option<Value>,
    shares_owned_following_transaction: Option<Value>,
    direct_or_indirect_ownership: Option<Value>,
}

#[derive(NifMap)]
pub struct DerivativeHolding {
    security_title: Option<Value>,
    exercise_date: Option<Value>,
    expiration_date: Option<Value>,
    underlying_security_title: Option<Value>,
    underlying_security_shares: Option<Value>,
    conversion_or_exercise_price: Option<Value>,
    shares_owned_following_transaction: Option<Value>,
    direct_or_indirect_ownership: Option<Value>,
}

#[rustler::nif]
pub fn parse_form4(xml: &str) -> Result<Document, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();

    let schema_version = get_string("schemaVersion", &root_node);
    let document_type = get_string("documentType", &root_node);
    let period_of_report = get_string("periodOfReport", &root_node);

    let issuer = parse_issuer(&root_node)?;
    let reporting_owner = parse_reporting_owner(&root_node)?;

    let non_derivative_table = parse_non_derivative_table(&root_node)?;
    let derivative_table = parse_derivative_table(&root_node)?;

    Ok(Document {
        schema_version,
        document_type,
        period_of_report,
        issuer,
        reporting_owner,
        non_derivative_table,
        derivative_table,
    })
}

fn parse_issuer(node: &roxmltree::Node) -> Result<Option<Issuer>, String> {
    node.children()
        .find(|node| node.has_tag_name("issuer"))
        .map(|issuer_node| {
            let cik = get_string("issuerCik", &issuer_node);
            let name = get_string("issuerName", &issuer_node);
            let trading_symbol = get_string("issuerTradingSymbol", &issuer_node);

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
            let id_node = owner_node
                .children()
                .find(|node| node.has_tag_name("reportingOwnerId"))
                .unwrap();

            let cik = get_string("rptOwnerCik", &id_node);
            let name = get_string("rptOwnerName", &id_node);

            let relationship_node = owner_node
                .children()
                .find(|node| node.has_tag_name("reportingOwnerRelationship"))
                .unwrap();

            let is_director = get_bool("isDirector", &relationship_node);
            let is_officer = get_bool("isOfficer", &relationship_node);
            let is_ten_percent_owner = get_bool("isTenPercentOwner", &relationship_node);
            let is_other = get_bool("isOther", &relationship_node);
            let officer_title = get_string("officerTitle", &relationship_node);

            let address = parse_reporting_owner_address(&owner_node)?;

            Ok(ReportingOwner {
                cik,
                name,
                is_director,
                is_officer,
                is_ten_percent_owner,
                is_other,
                officer_title,
                address,
            })
        })
        .transpose()
}

fn parse_reporting_owner_address(
    node: &roxmltree::Node,
) -> Result<Option<ReportingOwnerAddress>, String> {
    node.children()
        .find(|node| node.has_tag_name("reportingOwnerAddress"))
        .map(|address_node| {
            let street1 = get_string("rptOwnerStreet1", &address_node);
            let street2 = get_string("rptOwnerStreet2", &address_node);
            let city = get_string("rptOwnerCity", &address_node);
            let state = get_string("rptOwnerState", &address_node);
            let zip_code = get_string("rptOwnerZipCode", &address_node);
            let state_description = get_string("rptOwnerStateDescription", &address_node);

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

fn parse_non_derivative_transactions(
    node: &roxmltree::Node,
) -> Result<Vec<NonDerivativeTransaction>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("nonDerivativeTransaction"))
        .filter_map(|transaction_node| {
            let security_title = get_value("securityTitle", &transaction_node);
            let date = get_value("transactionDate", &transaction_node);
            let deemed_execution_date = get_value("deemedExecutionDate", &transaction_node);
            let timeliness = get_value("transactionTimeliness", &transaction_node);

            let coding_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("transactionCoding"))
                .unwrap();
            let form_type = get_string("transactionFormType", &coding_node);
            let code = get_string("transactionCode", &coding_node);
            let equity_swap_involved = get_bool("equitySwapInvolved", &coding_node);

            let amounts_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("transactionAmounts"))
                .unwrap();
            let shares = get_value("transactionShares", &amounts_node);
            let price_per_share = get_value("transactionPricePerShare", &amounts_node);
            let acquired_disposed_code =
                get_value("transactionAcquiredDisposedCode", &amounts_node);

            let post_amounts_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("postTransactionAmounts"))
                .unwrap();
            let shares_owned_following_transaction =
                get_value("sharesOwnedFollowingTransaction", &post_amounts_node);

            let ownership_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("ownershipNature"))
                .unwrap();
            let direct_or_indirect_ownership =
                get_value("directOrIndirectOwnership", &ownership_node);

            Some(NonDerivativeTransaction {
                security_title,
                date,
                deemed_execution_date,
                timeliness,
                form_type,
                code,
                equity_swap_involved,
                shares,
                price_per_share,
                acquired_disposed_code,
                shares_owned_following_transaction,
                direct_or_indirect_ownership,
            })
        })
        .collect();
    Ok(transactions)
}

fn parse_non_derivative_holdings(
    node: &roxmltree::Node,
) -> Result<Vec<NonDerivativeHolding>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("nonDerivativeHolding"))
        .filter_map(|holding_node| {
            let security_title = get_value("securityTitle", &holding_node);

            let post_amounts_node = holding_node
                .children()
                .find(|node| node.has_tag_name("postTransactionAmounts"))
                .unwrap();
            let shares_owned_following_transaction =
                get_value("sharesOwnedFollowingTransaction", &post_amounts_node);

            let ownership_node = holding_node
                .children()
                .find(|node| node.has_tag_name("ownershipNature"))
                .unwrap();
            let direct_or_indirect_ownership =
                get_value("directOrIndirectOwnership", &ownership_node);

            Some(NonDerivativeHolding {
                security_title,
                shares_owned_following_transaction,
                direct_or_indirect_ownership,
            })
        })
        .collect();
    Ok(transactions)
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

fn parse_derivative_transactions(
    node: &roxmltree::Node,
) -> Result<Vec<DerivativeTransaction>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("derivativeTransaction"))
        .filter_map(|transaction_node| {
            let security_title = get_value("securityTitle", &transaction_node);
            let date = get_value("transactionDate", &transaction_node);
            let exercise_date = get_value("exerciseDate", &transaction_node);
            let expiration_date = get_value("expirationDate", &transaction_node);

            let coding_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("transactionCoding"))
                .unwrap();
            let form_type = get_string("transactionFormType", &coding_node);
            let code = get_string("transactionCode", &coding_node);
            let equity_swap_involved = get_bool("equitySwapInvolved", &coding_node);

            let amounts_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("transactionAmounts"))
                .unwrap();
            let shares = get_value("transactionShares", &amounts_node);
            let price_per_share = get_value("transactionPricePerShare", &amounts_node);
            let acquired_disposed_code =
                get_value("transactionAcquiredDisposedCode", &amounts_node);

            let underlying_security_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("underlyingSecurity"))
                .unwrap();
            let underlying_security_title =
                get_value("underlyingSecurityTitle", &underlying_security_node);
            let underlying_security_shares =
                get_value("underlyingSecurityShares", &underlying_security_node);

            let conversion_or_exercise_price =
                get_value("conversionOrExercisePrice", &transaction_node);

            let post_amounts_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("postTransactionAmounts"))
                .unwrap();
            let shares_owned_following_transaction =
                get_value("sharesOwnedFollowingTransaction", &post_amounts_node);

            let ownership_node = transaction_node
                .children()
                .find(|node| node.has_tag_name("ownershipNature"))
                .unwrap();
            let direct_or_indirect_ownership =
                get_value("directOrIndirectOwnership", &ownership_node);

            Some(DerivativeTransaction {
                security_title,
                date,
                exercise_date,
                expiration_date,
                form_type,
                code,
                equity_swap_involved,
                shares,
                price_per_share,
                acquired_disposed_code,
                underlying_security_title,
                underlying_security_shares,
                conversion_or_exercise_price,
                shares_owned_following_transaction,
                direct_or_indirect_ownership,
            })
        })
        .collect();
    Ok(transactions)
}

fn parse_derivative_holdings(node: &roxmltree::Node) -> Result<Vec<DerivativeHolding>, String> {
    let transactions = node
        .children()
        .filter(|node| node.has_tag_name("derivativeHolding"))
        .filter_map(|holding_node| {
            let security_title = get_value("securityTitle", &holding_node);
            let exercise_date = get_value("exerciseDate", &holding_node);
            let expiration_date = get_value("expirationDate", &holding_node);

            let underlying_security_node = holding_node
                .children()
                .find(|node| node.has_tag_name("underlyingSecurity"))
                .unwrap();
            let underlying_security_title =
                get_value("underlyingSecurityTitle", &underlying_security_node);
            let underlying_security_shares =
                get_value("underlyingSecurityShares", &underlying_security_node);

            let conversion_or_exercise_price =
                get_value("conversionOrExercisePrice", &holding_node);

            let post_amounts_node = holding_node
                .children()
                .find(|node| node.has_tag_name("postTransactionAmounts"))
                .unwrap();
            let shares_owned_following_transaction =
                get_value("sharesOwnedFollowingTransaction", &post_amounts_node);

            let ownership_node = holding_node
                .children()
                .find(|node| node.has_tag_name("ownershipNature"))
                .unwrap();
            let direct_or_indirect_ownership =
                get_value("directOrIndirectOwnership", &ownership_node);

            Some(DerivativeHolding {
                security_title,
                exercise_date,
                expiration_date,
                underlying_security_title,
                underlying_security_shares,
                conversion_or_exercise_price,
                shares_owned_following_transaction,
                direct_or_indirect_ownership,
            })
        })
        .collect();
    Ok(transactions)
}
