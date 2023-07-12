use crate::get_string;
use roxmltree::Document as XMLDoc;
use rustler::NifMap;

#[derive(NifMap)]
pub struct Feed {
    title: Option<String>,
    link: Option<String>,
    description: Option<String>,
    language: Option<String>,
    items: Vec<Item>,
}

#[derive(NifMap)]
pub struct Item {
    title: Option<String>,
    link: Option<String>,
    description: Option<String>,
    pub_date: Option<String>,
}

#[rustler::nif]
pub fn parse_press_release_feed(xml: &str) -> Result<Feed, String> {
    let doc = XMLDoc::parse(xml).map_err(|e| e.to_string())?;
    let root_node = doc.root_element().first_element_child().unwrap();

    let title = get_string(&root_node, "title");
    let link = get_string(&root_node, "link");
    let description = get_string(&root_node, "description");
    let language = get_string(&root_node, "language");

    let items = root_node
        .children()
        .filter(|n| n.has_tag_name("item"))
        .map(|item_node| {
            let title = get_string(&item_node, "title");
            let link = get_string(&item_node, "link");
            let description = get_string(&item_node, "description");
            let pub_date = get_string(&item_node, "pubDate");

            Ok::<Item, String>(Item {
                title,
                link,
                description,
                pub_date,
            })
        })
        .collect::<Result<Vec<Item>, String>>()?;

    Ok(Feed {
        title,
        link,
        description,
        language,
        items,
    })
}
