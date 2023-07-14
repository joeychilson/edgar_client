use crate::{get_bool, get_int, get_ints, get_string};
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

// https://www.sec.gov/info/edgar/specifications/form13fxmltechspec

#[derive(NifMap)]
pub struct Document {
    schema_version: Option<String>,
    header_data: Option<HeaderData>,
    form_data: Option<FormData>,
}

#[derive(NifMap)]
pub struct HeaderData {
    submission_type: Option<String>,
    filer_info: Option<FilerInfo>,
}

#[derive(NifMap)]
pub struct FilerInfo {
    live_test_flag: Option<String>,
    flags: Option<Flags>,
    filer: Option<Filer>,
    contact: Option<Contact>,
    notifications: Option<Notifications>,
    period_of_report: Option<String>,
}

#[derive(NifMap)]
pub struct Flags {
    confirming_copy_flag: Option<bool>,
    return_copy_flag: Option<bool>,
    override_internet_flag: Option<bool>,
}

#[derive(NifMap)]
pub struct Filer {
    credentials: Option<Credentials>,
    file_number: Option<String>,
}

#[derive(NifMap)]
pub struct Credentials {
    cik: Option<String>,
    ccc: Option<String>,
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
    cover_page: Option<CoverPage>,
    signature_block: Option<SignatureBlock>,
    summary_page: Option<SummaryPage>,
    documents: Vec<OtherDocument>,
}

#[derive(NifMap)]
pub struct CoverPage {
    report_calendar_or_quarter: Option<String>,
    is_amendment: Option<bool>,
    amendment_number: Option<i64>,
    amendment_info: Option<AmendmentInfo>,
    filing_manager: Option<FilingManager>,
    report_type: Option<String>,
    form_13f_file_number: Option<String>,
    other_manager_info: Option<OtherManagerInfo>,
    provide_info_for_instruction_5: Option<bool>,
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
    name: Option<String>,
    address: Option<Address>,
}

#[derive(NifMap)]
pub struct Address {
    street1: Option<String>,
    street2: Option<String>,
    city: Option<String>,
    state_or_country: Option<String>,
    zip_code: Option<String>,
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
    name: Option<String>,
    title: Option<String>,
    phone: Option<String>,
    signature: Option<String>,
    city: Option<String>,
    state_or_country: Option<String>,
    signature_date: Option<String>,
}

#[derive(NifMap)]
pub struct SummaryPage {
    other_included_managers_count: Option<i64>,
    table_entry_total: Option<i64>,
    table_value_total: Option<i64>,
    is_confidential_omitted: Option<bool>,
    other_managers: Vec<OtherManagerWithSequence>,
}

#[derive(NifMap)]
pub struct OtherManagerWithSequence {
    sequence_number: Option<i64>,
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
    name_of_issuer: Option<String>,
    title_of_class: Option<String>,
    cusip: Option<String>,
    value: Option<i64>,
    shares_or_print_amount: Option<SharesOrPrintAmount>,
    put_call: Option<String>,
    investment_discretion: Option<String>,
    other_manager: Vec<i64>,
    voting_authority: Option<VotingAuthority>,
}

#[derive(NifMap)]
pub struct SharesOrPrintAmount {
    amount: Option<i64>,
    shares_or_print_type: Option<String>,
}

#[derive(NifMap)]
pub struct VotingAuthority {
    sole: Option<i64>,
    shared: Option<i64>,
    none: Option<i64>,
}

#[rustler::nif]
pub fn parse_form13f_document(xml: &str) -> Result<Document, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();

    let schema_version = get_string(&root_node, "schemaVersion");
    let header_data = parse_header_data(&root_node)?;
    let form_data = parse_form_data(&root_node)?;

    Ok(Document {
        schema_version,
        header_data,
        form_data,
    })
}

fn parse_header_data(node: &roxmltree::Node) -> Result<Option<HeaderData>, String> {
    node.children()
        .find(|n| n.has_tag_name("headerData"))
        .map(|header_data_node| {
            let submission_type = get_string(&header_data_node, "submissionType");
            let filer_info = parse_filer_info(&header_data_node)?;

            Ok(HeaderData {
                submission_type,
                filer_info,
            })
        })
        .transpose()
}

fn parse_filer_info(node: &roxmltree::Node) -> Result<Option<FilerInfo>, String> {
    node.children()
        .find(|n| n.has_tag_name("filerInfo"))
        .map(|filer_info_node| {
            let live_test_flag = get_string(&filer_info_node, "liveTestFlag");
            let flags = parse_flags(&filer_info_node)?;
            let filer = parse_filer(&filer_info_node)?;
            let contact = parse_contact(&filer_info_node)?;
            let notifications = parse_notifications(&filer_info_node)?;
            let period_of_report = get_string(&filer_info_node, "periodOfReport");

            Ok(FilerInfo {
                live_test_flag,
                flags,
                filer,
                contact,
                notifications,
                period_of_report,
            })
        })
        .transpose()
}

fn parse_flags(node: &roxmltree::Node) -> Result<Option<Flags>, String> {
    node.children()
        .find(|n| n.has_tag_name("flags"))
        .map(|flags_node| {
            let confirming_copy_flag = get_bool(&flags_node, "confirmingCopyFlag");
            let return_copy_flag = get_bool(&flags_node, "returnCopyFlag");
            let override_internet_flag = get_bool(&flags_node, "overrideInternetFlag");

            Ok(Flags {
                confirming_copy_flag,
                return_copy_flag,
                override_internet_flag,
            })
        })
        .transpose()
}

fn parse_filer(node: &roxmltree::Node) -> Result<Option<Filer>, String> {
    node.children()
        .find(|n| n.has_tag_name("filer"))
        .map(|filer_node| {
            let credentials = parse_credentials(&filer_node)?;
            let file_number = get_string(&filer_node, "fileNumber");

            Ok(Filer {
                credentials,
                file_number,
            })
        })
        .transpose()
}

fn parse_credentials(node: &roxmltree::Node) -> Result<Option<Credentials>, String> {
    node.children()
        .find(|n| n.has_tag_name("credentials"))
        .map(|credentials_node| {
            let cik = get_string(&credentials_node, "cik");
            let ccc = get_string(&credentials_node, "ccc");

            Ok(Credentials { cik, ccc })
        })
        .transpose()
}

fn parse_contact(node: &roxmltree::Node) -> Result<Option<Contact>, String> {
    node.children()
        .find(|n| n.has_tag_name("contact"))
        .map(|contact_node| {
            let name = get_string(&contact_node, "name");
            let phone_number = get_string(&contact_node, "phoneNumber");
            let email_address = get_string(&contact_node, "emailAddress");

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
        .find(|n| n.has_tag_name("notifications"))
        .map(|notifications_node| {
            let email_address = get_string(&notifications_node, "emailAddress");

            Ok(Notifications { email_address })
        })
        .transpose()
}

fn parse_form_data(node: &roxmltree::Node) -> Result<Option<FormData>, String> {
    node.children()
        .find(|n| n.has_tag_name("formData"))
        .map(|form_data_node| {
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
        .transpose()
}

fn parse_cover_page(node: &roxmltree::Node) -> Result<Option<CoverPage>, String> {
    node.children()
        .find(|n| n.has_tag_name("coverPage"))
        .map(|cover_page_node| {
            let report_calendar_or_quarter =
                get_string(&cover_page_node, "reportCalendarOrQuarter");
            let is_amendment = get_bool(&cover_page_node, "isAmendment");
            let amendment_number = get_int(&cover_page_node, "amendmentNumber");
            let amendment_info = parse_amendment_info(&cover_page_node)?;
            let filing_manager = parse_filing_manager(&cover_page_node)?;
            let report_type = get_string(&cover_page_node, "reportType");
            let form_13f_file_number = get_string(&cover_page_node, "form13FFileNumber");
            let other_manager_info = parse_other_manager_info(&cover_page_node)?;
            let provide_info_for_instruction_5 =
                get_bool(&cover_page_node, "provideInfoForInstruction5");
            let additional_information = get_string(&cover_page_node, "additionalInformation");

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
        .transpose()
}

fn parse_amendment_info(node: &roxmltree::Node) -> Result<Option<AmendmentInfo>, String> {
    node.children()
        .find(|n| n.has_tag_name("amendmentInfo"))
        .map(|amendment_info_node| {
            let amendment_type = get_string(&amendment_info_node, "amendmentType");
            let conf_denied_expired = get_bool(&amendment_info_node, "confDeniedExpired");
            let data_denied_expired = get_string(&amendment_info_node, "dataDeniedExpired");
            let date_reported = get_string(&amendment_info_node, "dataReported");
            let reason_for_non_confidentiality =
                get_string(&amendment_info_node, "reasonForNonConfidentiality");

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

fn parse_filing_manager(node: &roxmltree::Node) -> Result<Option<FilingManager>, String> {
    node.children()
        .find(|n| n.has_tag_name("filingManager"))
        .map(|filing_manager_node| {
            let name = get_string(&filing_manager_node, "name");
            let address = parse_filing_manager_address(&filing_manager_node)?;

            Ok(FilingManager { name, address })
        })
        .transpose()
}

fn parse_filing_manager_address(node: &roxmltree::Node) -> Result<Option<Address>, String> {
    node.children()
        .find(|n| n.has_tag_name("address"))
        .map(|filing_manager_address_node| {
            let street1 = get_string(&filing_manager_address_node, "street1");
            let street2 = get_string(&filing_manager_address_node, "street2");
            let city = get_string(&filing_manager_address_node, "city");
            let state_or_country = get_string(&filing_manager_address_node, "stateOrCountry");
            let zip_code = get_string(&filing_manager_address_node, "zipCode");

            Ok(Address {
                street1,
                street2,
                city,
                state_or_country,
                zip_code,
            })
        })
        .transpose()
}

fn parse_other_manager_info(node: &roxmltree::Node) -> Result<Option<OtherManagerInfo>, String> {
    node.children()
        .find(|n| n.has_tag_name("otherManagerInfo"))
        .map(|other_manager_info_node| {
            let other_manager = parse_other_manager(&other_manager_info_node)?;
            Ok(OtherManagerInfo { other_manager })
        })
        .transpose()
}

fn parse_other_manager(node: &roxmltree::Node) -> Result<Option<OtherManager>, String> {
    node.children()
        .find(|n| n.has_tag_name("otherManager"))
        .map(|other_manager_node| {
            let cik = get_string(&other_manager_node, "cik");
            let name = get_string(&other_manager_node, "name");
            let form_13f_file_number = get_string(&other_manager_node, "form13FFileNumber");

            Ok(OtherManager {
                cik,
                name,
                form_13f_file_number,
            })
        })
        .transpose()
}

fn parse_signature_block(node: &roxmltree::Node) -> Result<Option<SignatureBlock>, String> {
    node.children()
        .find(|n| n.has_tag_name("signatureBlock"))
        .map(|signature_block_node| {
            let name = get_string(&signature_block_node, "name");
            let title = get_string(&signature_block_node, "title");
            let phone = get_string(&signature_block_node, "phone");
            let signature = get_string(&signature_block_node, "signature");
            let city = get_string(&signature_block_node, "city");
            let state_or_country = get_string(&signature_block_node, "stateOrCountry");
            let signature_date = get_string(&signature_block_node, "signatureDate");

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
        .transpose()
}

fn parse_summary_page(node: &roxmltree::Node) -> Result<Option<SummaryPage>, String> {
    node.children()
        .find(|n| n.has_tag_name("summaryPage"))
        .map(|summary_page_node| {
            let other_included_managers_count =
                get_int(&summary_page_node, "otherIncludedManagersCount");
            let table_entry_total = get_int(&summary_page_node, "tableEntryTotal");
            let table_value_total = get_int(&summary_page_node, "tableValueTotal");
            let is_confidential_omitted = get_bool(&summary_page_node, "isConfidentialOmitted");
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
            let sequence_number = get_int(&manager_node, "sequenceNumber");
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
            let conformed_name = get_string(&manager_node, "conformedName");
            let conformed_document_type = get_string(&manager_node, "conformedDocumentType");
            let description = get_string(&manager_node, "description");
            let contents = get_string(&manager_node, "contents");

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
            let name_of_issuer = get_string(&info_node, "nameOfIssuer");
            let title_of_class = get_string(&info_node, "titleOfClass");
            let cusip = get_string(&info_node, "cusip");
            let value = get_int(&info_node, "value");
            let shares_or_print_amount = parse_shares_or_print_amount(&info_node).ok()?;
            let put_call = get_string(&info_node, "putCall");
            let investment_discretion = get_string(&info_node, "investmentDiscretion");
            let other_manager = get_ints(&info_node, "otherManager");
            let voting_authority = parse_voting_authority(&info_node).ok()?;

            Some(TableEntry {
                name_of_issuer,
                title_of_class,
                cusip,
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

fn parse_shares_or_print_amount(
    node: &roxmltree::Node,
) -> Result<Option<SharesOrPrintAmount>, String> {
    node.children()
        .find(|n| n.has_tag_name("shrsOrPrnAmt"))
        .map(|shares_or_principal_amount_node| {
            let amount = get_int(&shares_or_principal_amount_node, "sshPrnamt");
            let shares_or_print_type =
                get_string(&shares_or_principal_amount_node, "sshPrnamtType");

            Ok(SharesOrPrintAmount {
                amount,
                shares_or_print_type,
            })
        })
        .transpose()
}

fn parse_voting_authority(node: &roxmltree::Node) -> Result<Option<VotingAuthority>, String> {
    node.children()
        .find(|n| n.has_tag_name("votingAuthority"))
        .map(|voting_authority_node| {
            let sole = get_int(&voting_authority_node, "Sole");
            let shared = get_int(&voting_authority_node, "Shared");
            let none = get_int(&voting_authority_node, "None");

            Ok(VotingAuthority { sole, shared, none })
        })
        .transpose()
}
