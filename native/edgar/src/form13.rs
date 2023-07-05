use quick_xml::de::from_str;
use rustler::NifStruct;
use serde::Deserialize;

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Document"]
pub struct Document {
    #[serde(rename = "schemaVersion")]
    schema_version: String,
    #[serde(rename = "headerData")]
    header: Header,
    #[serde(rename = "formData")]
    form: Form,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Header"]
pub struct Header {
    #[serde(rename = "submissionType")]
    submission_type: String,
    #[serde(rename = "filerInfo")]
    filer_info: FilerInfo,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.FilerInfo"]
pub struct FilerInfo {
    #[serde(rename = "liveTestFlag")]
    live_test_flag: String,
    flags: Flags,
    filer: Filer,
    #[serde(rename = "periodOfReport")]
    period_of_report: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Flags"]
pub struct Flags {
    #[serde(rename = "confirmingCopyFlag")]
    confirming_copy_flag: Option<String>,
    #[serde(rename = "returnCopyFlag")]
    return_copy_flag: Option<String>,
    #[serde(rename = "overrideInternetFlag")]
    override_internet_flag: Option<String>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Filer"]
pub struct Filer {
    credentials: Credentials,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Credentials"]
pub struct Credentials {
    pub cik: String,
    pub ccc: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Form"]
pub struct Form {
    #[serde(rename = "coverPage")]
    cover_page: CoverPage,
    #[serde(rename = "signatureBlock")]
    signature_block: SignatureBlock,
    #[serde(rename = "summaryPage")]
    summary_page: SummaryPage,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.CoverPage"]
pub struct CoverPage {
    #[serde(rename = "reportCalendarOrQuarter")]
    report_calendar_or_quarter: String,
    #[serde(rename = "isAmendment")]
    is_amendment: Option<String>,
    #[serde(rename = "filingManager")]
    filing_manager: FilingManager,
    #[serde(rename = "reportType")]
    report_type: String,
    #[serde(rename = "form13FFileNumber")]
    form13f_file_number: String,
    #[serde(rename = "crdNumber")]
    crd_number: Option<String>,
    #[serde(rename = "secFileNumber")]
    sec_file_number: Option<String>,
    #[serde(rename = "provideInfoForInstruction5")]
    provide_info_for_instruction5: String,
    #[serde(rename = "additionalInformation")]
    additional_information: Option<String>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.FilingManager"]
struct FilingManager {
    name: String,
    address: Address,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Address"]
struct Address {
    #[serde(rename = "street1")]
    street1: String,
    #[serde(rename = "street2")]
    street2: Option<String>,
    #[serde(rename = "city")]
    city: String,
    #[serde(rename = "stateOrCountry")]
    state_or_country: String,
    #[serde(rename = "zipCode")]
    zip_code: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.SignatureBlock"]
pub struct SignatureBlock {
    name: String,
    title: String,
    phone: String,
    signature: String,
    city: String,
    #[serde(rename = "stateOrCountry")]
    state_or_country: String,
    #[serde(rename = "signatureDate")]
    signature_date: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.SummaryPage"]
pub struct SummaryPage {
    #[serde(rename = "otherIncludedManagersCount")]
    other_included_managers_count: u32,
    #[serde(rename = "tableEntryTotal")]
    table_entry_total: u32,
    #[serde(rename = "tableValueTotal")]
    table_value_total: u64,
}

#[rustler::nif]
pub fn parse_form13_document(xml: &str) -> Result<Document, String> {
    let document: Document = from_str::<Document>(xml).map_err(|e| e.to_string())?;
    Ok(document)
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Table"]
pub struct Table {
    #[serde(rename = "infoTable")]
    pub holdings: Vec<Holding>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.Holding"]
pub struct Holding {
    #[serde(rename = "nameOfIssuer")]
    pub name_of_issuer: String,
    #[serde(rename = "titleOfClass")]
    pub title_of_class: String,
    pub cusip: String,
    pub value: i64,
    #[serde(rename = "shrsOrPrnAmt")]
    pub shares_or_print_amount: SharesOrPrintAmount,
    #[serde(rename = "investmentDiscretion")]
    pub investment_discretion: String,
    #[serde(rename = "otherManager")]
    pub other_manager: Option<String>,
    #[serde(rename = "votingAuthority")]
    pub voting_authority: VotingAuthority,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.SharesOrPrintAmount"]
pub struct SharesOrPrintAmount {
    #[serde(rename = "sshPrnamt")]
    pub shares_or_print_amount: i64,
    #[serde(rename = "sshPrnamtType")]
    pub shares_or_print_type: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.Form13.VotingAuthority"]
pub struct VotingAuthority {
    #[serde(rename = "Sole")]
    pub sole: i64,
    #[serde(rename = "Shared")]
    pub shared: i64,
    #[serde(rename = "None")]
    pub none: i64,
}

#[rustler::nif]
pub fn parse_form13_table(xml: &str) -> Result<Table, String> {
    let table: Table = from_str::<Table>(xml).map_err(|e| e.to_string())?;
    Ok(table)
}
