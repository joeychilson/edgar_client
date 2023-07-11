mod company_feed;
mod current_feed;
mod ownership;
mod thirteenf;
mod xbrl;

use company_feed::parse_company_feed;
use current_feed::parse_current_feed;
use ownership::parse_ownership_form;
use thirteenf::{parse_13f_document, parse_13f_table};
use xbrl::parse_xbrl;

rustler::init!(
    "Elixir.EDGAR.Native",
    [
        parse_company_feed,
        parse_current_feed,
        parse_ownership_form,
        parse_13f_document,
        parse_13f_table,
        parse_xbrl,
    ]
);

#[derive(rustler::NifUntaggedEnum)]
pub enum Value {
    Int(i64),
    Float(f64),
    Text(String),
    Bool(bool),
}

pub fn get_string(node: &roxmltree::Node, tag: &str) -> Option<String> {
    node.children()
        .find(|node| node.has_tag_name(tag))
        .and_then(|node| node.text())
        .map(|s| s.to_string())
}

pub fn get_int(node: &roxmltree::Node, tag: &str) -> Option<i64> {
    get_string(node, tag).and_then(|text| text.parse::<i64>().ok())
}

pub fn get_ints(node: &roxmltree::Node, tag: &str) -> Vec<i64> {
    node.children()
        .filter(|node| node.has_tag_name(tag))
        .filter_map(|node| node.text())
        .flat_map(|text| text.split(',').filter_map(|s| s.trim().parse::<i64>().ok()))
        .collect()
}

pub fn get_bool(node: &roxmltree::Node, tag: &str) -> Option<bool> {
    get_string(node, tag).map(|text| text == "1" || text.to_uppercase() == "Y")
}

pub fn parse_value(value: String) -> Value {
    if let Ok(int_val) = value.parse::<i64>() {
        Value::Int(int_val)
    } else if let Ok(float_val) = value.parse::<f64>() {
        Value::Float(float_val)
    } else if value == "true" || value == "false" {
        Value::Bool(value == "true")
    } else {
        Value::Text(value)
    }
}
