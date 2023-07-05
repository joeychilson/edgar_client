use quick_xml::de::from_str;
use rustler::NifStruct;
use serde::Deserialize;

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Feed"]
pub struct Feed {
    id: String,
    title: String,
    updated: String,
    author: Author,
    #[serde(rename = "entry")]
    entries: Vec<Entry>,
    #[serde(rename = "link")]
    links: Vec<Link>,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Author"]
pub struct Author {
    email: String,
    name: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Entry"]
pub struct Entry {
    id: String,
    updated: String,
    title: String,
    category: Category,
    summary: Summary,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Summary"]
pub struct Summary {
    #[serde(rename = "@type")]
    summary_type: String,
    #[serde(rename = "$value")]
    value: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Category"]
pub struct Category {
    #[serde(rename = "@label")]
    label: String,
    #[serde(rename = "@scheme")]
    scheme: String,
    #[serde(rename = "@term")]
    term: String,
}

#[derive(Debug, Deserialize, NifStruct)]
#[module = "EDGAR.CurrentFeed.Link"]
pub struct Link {
    #[serde(rename = "@href")]
    href: String,
    #[serde(rename = "@rel")]
    rel: String,
    #[serde(rename = "@type")]
    link_type: Option<String>,
}

#[rustler::nif]
pub fn parse_current_feed(xml: &str) -> Result<Feed, String> {
    let feed = from_str::<Feed>(xml).map_err(|e| e.to_string())?;
    Ok(feed)
}
