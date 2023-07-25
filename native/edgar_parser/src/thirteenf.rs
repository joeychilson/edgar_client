use crate::xml::{get_bool, get_int32, get_int64, get_ints, get_string};
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

// https://www.sec.gov/info/edgar/specifications/form13fxmltechspec

#[derive(NifMap)]
pub struct Document {
    schema_version: Option<String>,
    header_data: HeaderData,
    form_data: FormData,
}

#[derive(NifMap)]
pub struct HeaderData {
    submission_type: String,
    filer_info: FilerInfo,
}

#[derive(NifMap)]
pub struct FilerInfo {
    live_test_flag: String,
    flags: Option<Flags>,
    filer: Filer,
    contact: Option<Contact>,
    notifications: Option<Notifications>,
    period_of_report: String,
}

#[derive(NifMap)]
pub struct Flags {
    confirming_copy_flag: Option<bool>,
    return_copy_flag: Option<bool>,
    override_internet_flag: Option<bool>,
}

#[derive(NifMap)]
pub struct Filer {
    credentials: Credentials,
    file_number: Option<String>,
}

#[derive(NifMap)]
pub struct Credentials {
    cik: String,
    ccc: String,
}

#[derive(NifMap)]
pub struct Contact {
    name: Option<String>,
    phone_number: Option<String>,
    email_address: Option<String>,
}

#[derive(NifMap)]
pub struct Notifications {
    email_address: Option<String>,
}

#[derive(NifMap)]
pub struct FormData {
    cover_page: CoverPage,
    signature_block: SignatureBlock,
    summary_page: Option<SummaryPage>,
    documents: Vec<OtherDocument>,
}

#[derive(NifMap)]
pub struct CoverPage {
    report_calendar_or_quarter: String,
    is_amendment: Option<bool>,
    amendment_number: Option<i32>,
    amendment_info: Option<AmendmentInfo>,
    filing_manager: FilingManager,
    report_type: String,
    form_13f_file_number: Option<String>,
    other_manager_info: Option<OtherManagerInfo>,
    provide_info_for_instruction_5: bool,
    additional_information: Option<String>,
}

#[derive(NifMap)]
pub struct AmendmentInfo {
    amendment_type: Option<String>,
    conf_denied_expired: Option<bool>,
    data_denied_expired: Option<String>,
    date_reported: Option<String>,
    reason_for_non_confidentiality: Option<String>,
}

#[derive(NifMap)]
pub struct FilingManager {
    name: String,
    address: Address,
}

#[derive(NifMap)]
pub struct Address {
    street1: String,
    street2: Option<String>,
    city: String,
    state_or_country: String,
    zip_code: String,
}

#[derive(NifMap)]
pub struct OtherManagerInfo {
    other_manager: Option<OtherManager>,
}

#[derive(NifMap)]
pub struct OtherManager {
    cik: Option<String>,
    name: Option<String>,
    form_13f_file_number: Option<String>,
}

#[derive(NifMap)]
pub struct SignatureBlock {
    name: String,
    title: String,
    phone: String,
    signature: String,
    city: String,
    state_or_country: String,
    signature_date: String,
}

#[derive(NifMap)]
pub struct SummaryPage {
    other_included_managers_count: i32,
    table_entry_total: i32,
    table_value_total: i64,
    is_confidential_omitted: Option<bool>,
    other_managers: Vec<OtherManagerWithSequence>,
}

#[derive(NifMap)]
pub struct OtherManagerWithSequence {
    sequence_number: Option<i32>,
    manager: Option<OtherManager>,
}

#[derive(NifMap)]
pub struct OtherDocument {
    conformed_name: Option<String>,
    conformed_document_type: Option<String>,
    description: Option<String>,
    contents: Option<String>,
}

#[derive(NifMap)]
pub struct Table {
    entries: Vec<TableEntry>,
}

#[derive(NifMap)]
pub struct TableEntry {
    name_of_issuer: String,
    title_of_class: String,
    cusip: String,
    figi: Option<String>,
    value: i64,
    shares_or_print_amount: SharesOrPrintAmount,
    put_call: Option<String>,
    investment_discretion: String,
    other_manager: Vec<i32>,
    voting_authority: VotingAuthority,
}

#[derive(NifMap)]
pub struct SharesOrPrintAmount {
    amount: i64,
    shares_or_print_type: String,
}

#[derive(NifMap)]
pub struct VotingAuthority {
    sole: i32,
    shared: i32,
    none: i32,
}

#[rustler::nif]
pub fn parse_form13f_document(xml: &str) -> Result<Document, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();
    let schema_version = get_string(&root_node, "schemaVersion").ok();
    let header_data = parse_header_data(&root_node)?;
    let form_data = parse_form_data(&root_node)?;

    Ok(Document {
        schema_version,
        header_data,
        form_data,
    })
}

fn parse_header_data(node: &roxmltree::Node) -> Result<HeaderData, String> {
    node.children()
        .find(|node| node.has_tag_name("headerData"))
        .ok_or("headerData not found".to_string())
        .and_then(|header_data_node| {
            let submission_type = get_string(&header_data_node, "submissionType")?;
            let filer_info = parse_filer_info(&header_data_node)?;

            Ok(HeaderData {
                submission_type,
                filer_info,
            })
        })
}

fn parse_filer_info(node: &roxmltree::Node) -> Result<FilerInfo, String> {
    node.children()
        .find(|node| node.has_tag_name("filerInfo"))
        .ok_or("filerInfo not found".to_string())
        .and_then(|filer_info_node| {
            let live_test_flag = get_string(&filer_info_node, "liveTestFlag")?;
            let flags = parse_flags(&filer_info_node)?;
            let filer = parse_filer(&filer_info_node)?;
            let contact = parse_contact(&filer_info_node)?;
            let notifications = parse_notifications(&filer_info_node)?;
            let period_of_report = get_string(&filer_info_node, "periodOfReport")?;

            Ok(FilerInfo {
                live_test_flag,
                flags,
                filer,
                contact,
                notifications,
                period_of_report,
            })
        })
}

fn parse_flags(node: &roxmltree::Node) -> Result<Option<Flags>, String> {
    node.children()
        .find(|node| node.has_tag_name("flags"))
        .map(|flags_node| {
            let confirming_copy_flag = get_bool(&flags_node, "confirmingCopyFlag").ok();
            let return_copy_flag = get_bool(&flags_node, "returnCopyFlag").ok();
            let override_internet_flag = get_bool(&flags_node, "overrideInternetFlag").ok();

            Ok(Flags {
                confirming_copy_flag,
                return_copy_flag,
                override_internet_flag,
            })
        })
        .transpose()
}

fn parse_filer(node: &roxmltree::Node) -> Result<Filer, String> {
    node.children()
        .find(|node| node.has_tag_name("filer"))
        .ok_or("filer not found".to_string())
        .and_then(|filer_node| {
            let credentials = parse_credentials(&filer_node)?;
            let file_number = get_string(&filer_node, "fileNumber").ok();

            Ok(Filer {
                credentials,
                file_number,
            })
        })
}

fn parse_credentials(node: &roxmltree::Node) -> Result<Credentials, String> {
    node.children()
        .find(|node| node.has_tag_name("credentials"))
        .ok_or("credentials not found".to_string())
        .and_then(|credentials_node| {
            let cik = get_string(&credentials_node, "cik")?;
            let ccc = get_string(&credentials_node, "ccc")?;

            Ok(Credentials { cik, ccc })
        })
}

fn parse_contact(node: &roxmltree::Node) -> Result<Option<Contact>, String> {
    node.children()
        .find(|node| node.has_tag_name("contact"))
        .map(|contact_node| {
            let name = get_string(&contact_node, "name").ok();
            let phone_number = get_string(&contact_node, "phoneNumber").ok();
            let email_address = get_string(&contact_node, "emailAddress").ok();

            Ok(Contact {
                name,
                phone_number,
                email_address,
            })
        })
        .transpose()
}

fn parse_notifications(node: &roxmltree::Node) -> Result<Option<Notifications>, String> {
    node.children()
        .find(|node| node.has_tag_name("notifications"))
        .map(|notifications_node| {
            let email_address = get_string(&notifications_node, "emailAddress").ok();

            Ok(Notifications { email_address })
        })
        .transpose()
}

fn parse_form_data(node: &roxmltree::Node) -> Result<FormData, String> {
    node.children()
        .find(|node| node.has_tag_name("formData"))
        .ok_or("formData not found".to_string())
        .and_then(|form_data_node| {
            let cover_page = parse_cover_page(&form_data_node)?;
            let signature_block = parse_signature_block(&form_data_node)?;
            let summary_page = parse_summary_page(&form_data_node)?;
            let documents = parse_documents(&form_data_node)?;

            Ok(FormData {
                cover_page,
                signature_block,
                summary_page,
                documents,
            })
        })
}

fn parse_cover_page(node: &roxmltree::Node) -> Result<CoverPage, String> {
    node.children()
        .find(|node| node.has_tag_name("coverPage"))
        .ok_or("coverPage not found".to_string())
        .and_then(|cover_page_node| {
            let report_calendar_or_quarter =
                get_string(&cover_page_node, "reportCalendarOrQuarter")?;
            let is_amendment = get_bool(&cover_page_node, "isAmendment").ok();
            let amendment_number = get_int32(&cover_page_node, "amendmentNumber").ok();
            let amendment_info = parse_amendment_info(&cover_page_node)?;
            let filing_manager = parse_filing_manager(&cover_page_node)?;
            let report_type = get_string(&cover_page_node, "reportType")?;
            let form_13f_file_number = get_string(&cover_page_node, "form13FFileNumber").ok();
            let other_manager_info = parse_other_manager_info(&cover_page_node)?;
            let provide_info_for_instruction_5 =
                get_bool(&cover_page_node, "provideInfoForInstruction5")?;
            let additional_information = get_string(&cover_page_node, "additionalInformation").ok();

            Ok(CoverPage {
                report_calendar_or_quarter,
                is_amendment,
                amendment_number,
                amendment_info,
                filing_manager,
                report_type,
                form_13f_file_number,
                other_manager_info,
                provide_info_for_instruction_5,
                additional_information,
            })
        })
}

fn parse_amendment_info(node: &roxmltree::Node) -> Result<Option<AmendmentInfo>, String> {
    node.children()
        .find(|node| node.has_tag_name("amendmentInfo"))
        .map(|amendment_info_node| {
            let amendment_type = get_string(&amendment_info_node, "amendmentType").ok();
            let conf_denied_expired = get_bool(&amendment_info_node, "confDeniedExpired").ok();
            let data_denied_expired = get_string(&amendment_info_node, "dataDeniedExpired").ok();
            let date_reported = get_string(&amendment_info_node, "dataReported").ok();
            let reason_for_non_confidentiality =
                get_string(&amendment_info_node, "reasonForNonConfidentiality").ok();

            Ok(AmendmentInfo {
                amendment_type,
                conf_denied_expired,
                data_denied_expired,
                date_reported,
                reason_for_non_confidentiality,
            })
        })
        .transpose()
}

fn parse_filing_manager(node: &roxmltree::Node) -> Result<FilingManager, String> {
    node.children()
        .find(|node| node.has_tag_name("filingManager"))
        .ok_or("filingManager not found".to_string())
        .and_then(|filing_manager_node| {
            let name = get_string(&filing_manager_node, "name")?;
            let address = parse_filing_manager_address(&filing_manager_node)?;

            Ok(FilingManager { name, address })
        })
}

fn parse_filing_manager_address(node: &roxmltree::Node) -> Result<Address, String> {
    node.children()
        .find(|node| node.has_tag_name("address"))
        .ok_or("address not found".to_string())
        .and_then(|filing_manager_address_node| {
            let street1 = get_string(&filing_manager_address_node, "street1")?;
            let street2 = get_string(&filing_manager_address_node, "street2").ok();
            let city = get_string(&filing_manager_address_node, "city")?;
            let state_or_country = get_string(&filing_manager_address_node, "stateOrCountry")?;
            let zip_code = get_string(&filing_manager_address_node, "zipCode")?;

            Ok(Address {
                street1,
                street2,
                city,
                state_or_country,
                zip_code,
            })
        })
}

fn parse_other_manager_info(node: &roxmltree::Node) -> Result<Option<OtherManagerInfo>, String> {
    node.children()
        .find(|node| node.has_tag_name("otherManagerInfo"))
        .map(|other_manager_info_node| {
            let other_manager = parse_other_manager(&other_manager_info_node)?;
            Ok(OtherManagerInfo { other_manager })
        })
        .transpose()
}

fn parse_other_manager(node: &roxmltree::Node) -> Result<Option<OtherManager>, String> {
    node.children()
        .find(|node| node.has_tag_name("otherManager"))
        .map(|other_manager_node| {
            let cik = get_string(&other_manager_node, "cik").ok();
            let name = get_string(&other_manager_node, "name").ok();
            let form_13f_file_number = get_string(&other_manager_node, "form13FFileNumber").ok();

            Ok(OtherManager {
                cik,
                name,
                form_13f_file_number,
            })
        })
        .transpose()
}

fn parse_signature_block(node: &roxmltree::Node) -> Result<SignatureBlock, String> {
    node.children()
        .find(|node| node.has_tag_name("signatureBlock"))
        .ok_or("signatureBlock not found".to_string())
        .and_then(|signature_block_node| {
            let name = get_string(&signature_block_node, "name")?;
            let title = get_string(&signature_block_node, "title")?;
            let phone = get_string(&signature_block_node, "phone")?;
            let signature = get_string(&signature_block_node, "signature")?;
            let city = get_string(&signature_block_node, "city")?;
            let state_or_country = get_string(&signature_block_node, "stateOrCountry")?;
            let signature_date = get_string(&signature_block_node, "signatureDate")?;

            Ok(SignatureBlock {
                name,
                title,
                phone,
                signature,
                city,
                state_or_country,
                signature_date,
            })
        })
}

fn parse_summary_page(node: &roxmltree::Node) -> Result<Option<SummaryPage>, String> {
    node.children()
        .find(|node| node.has_tag_name("summaryPage"))
        .map(|summary_page_node| {
            let other_included_managers_count =
                get_int32(&summary_page_node, "otherIncludedManagersCount")?;
            let table_entry_total = get_int32(&summary_page_node, "tableEntryTotal")?;
            let table_value_total = get_int64(&summary_page_node, "tableValueTotal")?;
            let is_confidential_omitted =
                get_bool(&summary_page_node, "isConfidentialOmitted").ok();
            let other_managers = parse_other_managers(&summary_page_node)?;

            Ok(SummaryPage {
                other_included_managers_count,
                table_entry_total,
                table_value_total,
                is_confidential_omitted,
                other_managers,
            })
        })
        .transpose()
}

fn parse_other_managers(node: &roxmltree::Node) -> Result<Vec<OtherManagerWithSequence>, String> {
    let managers = node
        .children()
        .filter(|node| node.has_tag_name("otherManagers2Info"))
        .flat_map(|node| node.children())
        .filter(|node| node.has_tag_name("otherManager2"))
        .filter_map(|manager_node| {
            let sequence_number = get_int32(&manager_node, "sequenceNumber").ok();
            let manager = parse_other_manager(&manager_node).ok()?;

            Some(OtherManagerWithSequence {
                sequence_number,
                manager,
            })
        })
        .collect();
    Ok(managers)
}

fn parse_documents(node: &roxmltree::Node) -> Result<Vec<OtherDocument>, String> {
    let documents = node
        .children()
        .filter(|node| node.has_tag_name("documents"))
        .flat_map(|node| node.children())
        .filter(|node| node.has_tag_name("document"))
        .filter_map(|manager_node| {
            let conformed_name = get_string(&manager_node, "conformedName").ok();
            let conformed_document_type = get_string(&manager_node, "conformedDocumentType").ok();
            let description = get_string(&manager_node, "description").ok();
            let contents = get_string(&manager_node, "contents").ok();

            Some(OtherDocument {
                conformed_name,
                conformed_document_type,
                description,
                contents,
            })
        })
        .collect();
    Ok(documents)
}

#[rustler::nif]
pub fn parse_form13f_table(xml: &str) -> Result<Table, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();

    let entries = root_node
        .children()
        .filter(|root_node| root_node.has_tag_name("infoTable"))
        .filter_map(|info_node| {
            let name_of_issuer = get_string(&info_node, "nameOfIssuer").ok()?;
            let title_of_class = get_string(&info_node, "titleOfClass").ok()?;
            let cusip = get_string(&info_node, "cusip").ok()?;
            let figi = get_string(&info_node, "figi").ok();
            let value = get_int64(&info_node, "value").ok()?;
            let shares_or_print_amount = parse_shares_or_print_amount(&info_node).ok()?;
            let put_call = get_string(&info_node, "putCall").ok();
            let investment_discretion = get_string(&info_node, "investmentDiscretion").ok()?;
            let other_manager = get_ints(&info_node, "otherManager");
            let voting_authority = parse_voting_authority(&info_node).ok()?;

            Some(TableEntry {
                name_of_issuer,
                title_of_class,
                cusip,
                figi,
                value,
                shares_or_print_amount,
                put_call,
                investment_discretion,
                other_manager,
                voting_authority,
            })
        })
        .collect();

    Ok(Table { entries })
}

fn parse_shares_or_print_amount(node: &roxmltree::Node) -> Result<SharesOrPrintAmount, String> {
    node.children()
        .find(|node| node.has_tag_name("shrsOrPrnAmt"))
        .ok_or("shrsOrPrnAmt not found".to_string())
        .and_then(|shares_or_principal_amount_node| {
            let amount = get_int64(&shares_or_principal_amount_node, "sshPrnamt")?;
            let shares_or_print_type =
                get_string(&shares_or_principal_amount_node, "sshPrnamtType")?;

            Ok(SharesOrPrintAmount {
                amount,
                shares_or_print_type,
            })
        })
}

fn parse_voting_authority(node: &roxmltree::Node) -> Result<VotingAuthority, String> {
    node.children()
        .find(|node| node.has_tag_name("votingAuthority"))
        .ok_or("votingAuthority not found".to_string())
        .and_then(|voting_authority_node| {
            let sole = get_int32(&voting_authority_node, "Sole")?;
            let shared = get_int32(&voting_authority_node, "Shared")?;
            let none = get_int32(&voting_authority_node, "None")?;

            Ok(VotingAuthority { sole, shared, none })
        })
}
