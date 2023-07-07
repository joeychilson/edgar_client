use roxmltree::Document as XMLDoc;
use rustler::{NifMap, NifTaggedEnum};
use std::collections::HashMap;

#[derive(NifMap)]
pub struct Document {
    facts: Vec<Fact>,
}

#[derive(NifMap)]
pub struct Fact {
    context: Context,
    concept: String,
    value: Value,
    decimals: Option<String>,
    unit: Option<String>,
}

#[derive(NifTaggedEnum)]
enum Value {
    Int(i64),
    Float(f64),
    Text(String),
}

#[derive(Clone, NifMap)]
pub struct Context {
    entity: String,
    segments: Vec<Segment>,
    period: Period,
}

#[derive(Clone, NifMap)]
pub struct Segment {
    dimension: String,
    member: String,
}

#[derive(Clone, NifMap)]
pub struct Period {
    instant: Option<String>,
    start_date: Option<String>,
    end_date: Option<String>,
}

#[rustler::nif]
pub fn parse_xbrl(xbrl: &str) -> Result<Document, String> {
    let doc = XMLDoc::parse(xbrl).map_err(|e| e.to_string())?;
    let root = doc.root_element();

    let xbrldi_ns = root
        .namespaces()
        .iter()
        .find(|ns| ns.name() == Some("xbrldi"))
        .map(|ns| ns.uri())
        .unwrap_or("");

    let units = parse_units(&root)?;
    let contexts = parse_contexts(&root, &xbrldi_ns)?;

    let mut facts = Vec::new();

    for node in root.children() {
        if let Some(context_ref) = node.attribute("contextRef") {
            if let Some(context) = contexts.get(context_ref) {
                let tag = node.tag_name().name().to_string();
                let value_str = node.text().unwrap_or_default().to_string();
                let value = if let Ok(int_val) = value_str.parse::<i64>() {
                    Value::Int(int_val)
                } else if let Ok(float_val) = value_str.parse::<f64>() {
                    Value::Float(float_val)
                } else {
                    Value::Text(value_str)
                };
                let decimals = node.attribute("decimals").map(|s| s.to_string());

                let unit = if let Some(unit_ref) = node.attribute("unitRef") {
                    units.get(unit_ref).cloned()
                } else {
                    None
                };

                facts.push(Fact {
                    context: context.clone(),
                    concept: tag,
                    value,
                    decimals,
                    unit,
                });
            }
        }
    }

    Ok(Document { facts: facts })
}

fn parse_units(root: &roxmltree::Node) -> Result<HashMap<String, String>, String> {
    let mut units = HashMap::new();
    for unit_node in root.children().filter(|node| node.has_tag_name("unit")) {
        let unit_id = unit_node.attribute("id").unwrap_or_default().to_string();
        let measure: String;

        if let Some(divide_node) = unit_node
            .children()
            .find(|node| node.has_tag_name("divide"))
        {
            let numerator_measure = divide_node
                .children()
                .find(|node| node.has_tag_name("unitNumerator"))
                .and_then(|node| node.children().find(|n| n.has_tag_name("measure")))
                .and_then(|node| node.text())
                .unwrap_or_default()
                .to_string();
            let denominator_measure = divide_node
                .children()
                .find(|node| node.has_tag_name("unitDenominator"))
                .and_then(|node| node.children().find(|n| n.has_tag_name("measure")))
                .and_then(|node| node.text())
                .unwrap_or_default()
                .to_string();
            measure = format!("{}/{}", numerator_measure, denominator_measure);
        } else {
            measure = unit_node
                .children()
                .find(|node| node.has_tag_name("measure"))
                .and_then(|node| node.text())
                .unwrap_or_default()
                .to_string();
        }

        units.insert(unit_id, measure);
    }
    Ok(units)
}
fn parse_contexts(
    root: &roxmltree::Node,
    xbrldi_ns: &str,
) -> Result<HashMap<String, Context>, String> {
    let mut contexts = HashMap::new();

    for context_node in root.children().filter(|node| node.has_tag_name("context")) {
        let context_id = context_node.attribute("id").unwrap().to_string();

        let entity_node = context_node
            .children()
            .find(|node| node.has_tag_name("entity"))
            .unwrap();
        let entity = entity_node
            .children()
            .find(|node| node.has_tag_name("identifier"))
            .unwrap()
            .text()
            .unwrap()
            .to_string();

        let mut segments = vec![];
        for segment_node in entity_node
            .children()
            .filter(|node| node.has_tag_name("segment"))
        {
            for member_node in segment_node
                .children()
                .filter(|node| node.has_tag_name((xbrldi_ns, "explicitMember")))
            {
                let raw_dimension = member_node.attribute("dimension").unwrap().to_string();
                let dimension = raw_dimension
                    .split(":")
                    .collect::<Vec<&str>>()
                    .get(1)
                    .unwrap_or(&"")
                    .to_string();
                let raw_member = member_node.text().unwrap().to_string();
                let member = raw_member
                    .split(":")
                    .collect::<Vec<&str>>()
                    .get(1)
                    .unwrap_or(&"")
                    .to_string();

                segments.push(Segment { dimension, member });
            }
        }

        let period_node = context_node
            .children()
            .find(|node| node.has_tag_name("period"))
            .unwrap();
        let instant = period_node
            .children()
            .find(|node| node.has_tag_name("instant"))
            .and_then(|node| node.text())
            .map(|s| s.to_string());
        let start_date = period_node
            .children()
            .find(|node| node.has_tag_name("startDate"))
            .and_then(|node| node.text())
            .map(|s| s.to_string());
        let end_date = period_node
            .children()
            .find(|node| node.has_tag_name("endDate"))
            .and_then(|node| node.text())
            .map(|s| s.to_string());

        contexts.insert(
            context_id,
            Context {
                entity,
                segments,
                period: Period {
                    instant,
                    start_date,
                    end_date,
                },
            },
        );
    }

    Ok(contexts)
}
