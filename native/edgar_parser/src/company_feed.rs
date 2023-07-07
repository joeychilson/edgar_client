use quick_xml::de::from_str;
use rustler::NifMap;
use serde::Deserialize;

#[derive(Debug, Deserialize, NifMap)]
pub struct Feed {
    id: String,
    title: String,
    updated: String,
    author: Author,
    #[serde(rename = "company-info")]
    company_info: CompanyInfo,
    #[serde(rename = "entry")]
    entries: Vec<Entry>,
    #[serde(rename = "link")]
    links: Vec<Link>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Author {
    email: String,
    name: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct CompanyInfo {
    #[serde(rename = "addresses")]
    addresses: Addresses,
    #[serde(rename = "assigned-sic")]
    assigned_sic: i32,
    #[serde(rename = "assigned-sic-desc")]
    assigned_sic_desc: String,
    #[serde(rename = "assigned-sic-href")]
    assigned_sic_href: String,
    #[serde(rename = "cik")]
    cik: String,
    #[serde(rename = "cik-href")]
    cik_href: String,
    #[serde(rename = "conformed-name")]
    conformed_name: String,
    #[serde(rename = "fiscal-year-end")]
    fiscal_year_end: i32,
    #[serde(rename = "office")]
    office: String,
    #[serde(rename = "state-location")]
    state_location: String,
    #[serde(rename = "state-location-href")]
    state_location_href: String,
    #[serde(rename = "state-of-incorporation")]
    state_of_incorporation: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Addresses {
    #[serde(rename = "address")]
    addresses: Vec<Address>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Address {
    #[serde(rename = "@type")]
    address_type: String,
    city: String,
    phone: Option<String>,
    state: String,
    street1: String,
    street2: Option<String>,
    zip: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Entry {
    category: Category,
    content: Content,
    id: String,
    link: Link,
    summary: Summary,
    title: String,
    updated: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Category {
    #[serde(rename = "@label")]
    label: String,
    #[serde(rename = "@scheme")]
    scheme: String,
    #[serde(rename = "@term")]
    term: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Content {
    #[serde(rename = "@type")]
    content_type: String,
    #[serde(rename = "accession-number")]
    accession_number: String,
    #[serde(rename = "file-number")]
    file_number: Option<String>,
    #[serde(rename = "file-number-href")]
    file_number_href: Option<String>,
    #[serde(rename = "filing-date")]
    filing_date: String,
    #[serde(rename = "filing-href")]
    filing_href: String,
    #[serde(rename = "filing-type")]
    filing_type: String,
    #[serde(rename = "film-number")]
    film_number: Option<i32>,
    #[serde(rename = "form-name")]
    form_name: String,
    size: String,
    xbrl_href: Option<String>,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Link {
    #[serde(rename = "@href")]
    href: String,
    #[serde(rename = "@rel")]
    rel: String,
    #[serde(rename = "@type")]
    link_type: String,
}

#[derive(Debug, Deserialize, NifMap)]
pub struct Summary {
    #[serde(rename = "@type")]
    summary_type: String,
    #[serde(rename = "$value")]
    value: String,
}

#[rustler::nif]
pub fn parse_company_feed(xml: &str) -> Result<Feed, String> {
    let feed = from_str::<Feed>(xml).map_err(|e| e.to_string())?;
    Ok(feed)
}
