use crate::{get_int, get_string};
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

// https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0000789019&output=atom

#[derive(NifMap)]
pub struct Feed {
    id: Option<String>,
    title: Option<String>,
    updated: Option<String>,
    author: Option<Author>,
    company_info: Option<CompanyInfo>,
    entries: Vec<Entry>,
    links: Vec<Link>,
}

#[derive(NifMap)]
pub struct Author {
    email: Option<String>,
    name: Option<String>,
}

#[derive(NifMap)]
pub struct CompanyInfo {
    addresses: Option<Addresses>,
    assigned_sic: Option<i64>,
    assigned_sic_desc: Option<String>,
    assigned_sic_href: Option<String>,
    cik: Option<String>,
    cik_href: Option<String>,
    conformed_name: Option<String>,
    fiscal_year_end: Option<i64>,
    office: Option<String>,
    state_location: Option<String>,
    state_location_href: Option<String>,
    state_of_incorporation: Option<String>,
}

#[derive(NifMap)]
pub struct Addresses {
    addresses: Vec<Address>,
}

#[derive(NifMap)]
pub struct Address {
    address_type: Option<String>,
    city: Option<String>,
    phone: Option<String>,
    state: Option<String>,
    street1: Option<String>,
    street2: Option<String>,
    zip: Option<String>,
}

#[derive(NifMap)]
pub struct Entry {
    category: Option<Category>,
    content: Option<Content>,
    id: Option<String>,
    link: Option<Link>,
    summary: Option<Summary>,
    title: Option<String>,
    updated: Option<String>,
}

#[derive(NifMap)]
pub struct Category {
    label: Option<String>,
    scheme: Option<String>,
    term: Option<String>,
}

#[derive(NifMap)]
pub struct Content {
    content_type: Option<String>,
    accession_number: Option<String>,
    act: Option<String>,
    file_number: Option<String>,
    file_number_href: Option<String>,
    filing_date: Option<String>,
    filing_href: Option<String>,
    filing_type: Option<String>,
    film_number: Option<i64>,
    form_name: Option<String>,
    items_desc: Option<String>,
    size: Option<String>,
    xbrl_href: Option<String>,
}

#[derive(NifMap)]
pub struct Link {
    href: Option<String>,
    rel: Option<String>,
    link_type: Option<String>,
}

#[derive(NifMap)]
pub struct Summary {
    summary_type: Option<String>,
    summary: Option<String>,
}

#[rustler::nif]
pub fn parse_company_feed(xml: &str) -> Result<Feed, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element();

    let id = get_string(&root_node, "id");
    let title = get_string(&root_node, "title");
    let updated = get_string(&root_node, "updated");

    let links = root_node
        .children()
        .filter(|n| n.has_tag_name("link"))
        .map(|link_node| {
            let href = link_node.attribute("href").map(|s| s.to_string());
            let rel = link_node.attribute("rel").map(|s| s.to_string());
            let link_type = link_node.attribute("type").map(|s| s.to_string());

            Ok(Link {
                href,
                rel,
                link_type,
            })
        })
        .collect::<Result<Vec<Link>, String>>()?;

    let author = root_node
        .children()
        .find(|n| n.has_tag_name("author"))
        .map(|author_node| {
            let name = get_string(&author_node, "name");
            let email = get_string(&author_node, "email");

            Ok::<Author, String>(Author { name, email })
        })
        .transpose()?;

    let company_info = root_node
        .children()
        .find(|n| n.has_tag_name("company-info"))
        .map(|company_node| {
            let assigned_sic = get_int(&company_node, "assigned-sic");
            let assigned_sic_desc = get_string(&company_node, "assigned-sic-desc");
            let assigned_sic_href = get_string(&company_node, "assigned-sic-href");
            let cik = get_string(&company_node, "cik");
            let cik_href = get_string(&company_node, "cik-href");
            let conformed_name = get_string(&company_node, "conformed-name");
            let fiscal_year_end = get_int(&company_node, "fiscal-year-end");
            let office = get_string(&company_node, "office");
            let state_location = get_string(&company_node, "state-location");
            let state_location_href = get_string(&company_node, "state-location-href");
            let state_of_incorporation = get_string(&company_node, "state-of-incorporation");

            let addresses = company_node
                .children()
                .find(|n| n.has_tag_name("addresses"))
                .and_then(|addresses_node| {
                    let addresses = addresses_node
                        .children()
                        .filter(|n| n.has_tag_name("address"))
                        .map(|address_node| {
                            let address_type = get_string(&address_node, "address-type");
                            let city = get_string(&address_node, "city");
                            let phone = get_string(&address_node, "phone");
                            let state = get_string(&address_node, "state");
                            let street1 = get_string(&address_node, "street1");
                            let street2 = get_string(&address_node, "street2");
                            let zip = get_string(&address_node, "zip");

                            Ok::<Address, String>(Address {
                                address_type,
                                city,
                                phone,
                                state,
                                street1,
                                street2,
                                zip,
                            })
                        })
                        .collect::<Result<Vec<Address>, String>>()
                        .ok();

                    addresses.map(|addresses| Addresses { addresses })
                });

            Ok::<CompanyInfo, String>(CompanyInfo {
                addresses,
                assigned_sic,
                assigned_sic_desc,
                assigned_sic_href,
                cik,
                cik_href,
                conformed_name,
                fiscal_year_end,
                office,
                state_location,
                state_location_href,
                state_of_incorporation,
            })
        })
        .transpose()?;

    let entries = root_node
        .children()
        .filter(|n| n.has_tag_name("entry"))
        .map(|entry_node| {
            let id = get_string(&entry_node, "id");
            let updated = get_string(&entry_node, "updated");
            let title = get_string(&entry_node, "title");

            let link = entry_node
                .children()
                .find(|n| n.has_tag_name("link"))
                .map(|link_node| {
                    let href = link_node.attribute("href").map(|s| s.to_string());
                    let rel = link_node.attribute("rel").map(|s| s.to_string());
                    let link_type = link_node.attribute("type").map(|s| s.to_string());

                    Ok::<Link, String>(Link {
                        href,
                        rel,
                        link_type,
                    })
                })
                .transpose()?;

            let category = entry_node
                .children()
                .find(|n| n.has_tag_name("category"))
                .map(|category_node| {
                    let label = category_node.attribute("label").map(|s| s.to_string());
                    let scheme = category_node.attribute("scheme").map(|s| s.to_string());
                    let term = category_node.attribute("term").map(|s| s.to_string());

                    Ok::<Category, String>(Category {
                        label,
                        scheme,
                        term,
                    })
                })
                .transpose()?;

            let summary = entry_node
                .children()
                .find(|n| n.has_tag_name("summary"))
                .map(|summary_node| {
                    let summary_type = summary_node.attribute("type").map(|s| s.to_string());
                    let summary = summary_node.text().map(|s| s.to_string());

                    Ok::<Summary, String>(Summary {
                        summary_type,
                        summary,
                    })
                })
                .transpose()?;

            let content = entry_node
                .children()
                .find(|n| n.has_tag_name("content"))
                .map(|content_node| {
                    let content_type = content_node.attribute("type").map(|s| s.to_string());
                    let accession_number = get_string(&content_node, "accession-number");
                    let act = get_string(&content_node, "act");
                    let file_number = get_string(&content_node, "file-number");
                    let file_number_href = get_string(&content_node, "file-number-href");
                    let filing_date = get_string(&content_node, "filing-date");
                    let filing_href = get_string(&content_node, "filing-href");
                    let filing_type = get_string(&content_node, "filing-type");
                    let film_number = get_int(&content_node, "film-number");
                    let form_name = get_string(&content_node, "form-name");
                    let items_desc = get_string(&content_node, "items-desc");
                    let size = get_string(&content_node, "size");
                    let xbrl_href = get_string(&content_node, "xbrl_href");

                    Ok::<Content, String>(Content {
                        content_type,
                        accession_number,
                        act,
                        file_number,
                        file_number_href,
                        filing_date,
                        filing_href,
                        filing_type,
                        film_number,
                        form_name,
                        items_desc,
                        size,
                        xbrl_href,
                    })
                })
                .transpose()?;

            Ok::<Entry, String>(Entry {
                id,
                updated,
                title,
                link,
                category,
                summary,
                content,
            })
        })
        .collect::<Result<Vec<Entry>, String>>()?;

    Ok(Feed {
        id,
        title,
        updated,
        links,
        author,
        company_info,
        entries,
    })
}
