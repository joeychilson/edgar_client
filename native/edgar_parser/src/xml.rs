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

pub fn get_int32(node: &roxmltree::Node, tag: &str) -> Option<i32> {
    get_string(node, tag).and_then(|text| text.parse::<i32>().ok())
}

pub fn get_int64(node: &roxmltree::Node, tag: &str) -> Option<i64> {
    get_string(node, tag).and_then(|text| text.parse::<i64>().ok())
}

pub fn get_ints(node: &roxmltree::Node, tag: &str) -> Vec<i32> {
    node.children()
        .filter(|node| node.has_tag_name(tag))
        .filter_map(|node| node.text())
        .flat_map(|text| text.split(',').filter_map(|s| s.trim().parse::<i32>().ok()))
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
