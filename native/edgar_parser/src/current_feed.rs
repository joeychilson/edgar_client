use crate::get_string;
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

// https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&CIK=&type=&company=&dateb=&owner=include&start=0&count=40&output=atom

#[derive(NifMap)]
pub struct Feed {
    id: Option<String>,
    title: Option<String>,
    updated: Option<String>,
    author: Option<Author>,
    entries: Vec<Entry>,
    links: Vec<Link>,
}

#[derive(NifMap)]
pub struct Author {
    email: Option<String>,
    name: Option<String>,
}

#[derive(NifMap)]
pub struct Entry {
    id: Option<String>,
    updated: Option<String>,
    title: Option<String>,
    link: Option<Link>,
    category: Option<Category>,
    summary: Option<Summary>,
}

#[derive(NifMap)]
pub struct Summary {
    summary_type: Option<String>,
    summary: Option<String>,
}

#[derive(NifMap)]
pub struct Category {
    label: Option<String>,
    scheme: Option<String>,
    term: Option<String>,
}

#[derive(NifMap)]
pub struct Link {
    href: Option<String>,
    rel: Option<String>,
    link_type: Option<String>,
}

#[rustler::nif]
pub fn parse_current_feed(xml: &str) -> Result<Feed, String> {
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

            Ok(Entry {
                id,
                updated,
                title,
                link,
                category,
                summary,
            })
        })
        .collect::<Result<Vec<Entry>, String>>()?;

    Ok(Feed {
        id,
        title,
        updated,
        author,
        entries,
        links,
    })
}
