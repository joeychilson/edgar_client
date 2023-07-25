#[derive(rustler::NifUntaggedEnum)]
pub enum Value {
    Int(i64),
    Float(f64),
    Text(String),
    Bool(bool),
}

pub fn get_string(node: &roxmltree::Node, tag: &str) -> Result<String, String> {
    node.children()
        .find(|node| node.has_tag_name(tag))
        .and_then(|node| node.text())
        .map(|s| s.to_string())
        .ok_or(format!("missing tag: {}", tag))
}

pub fn get_int32(node: &roxmltree::Node, tag: &str) -> Result<i32, String> {
    let text = get_string(node, tag)?;
    text.parse::<i32>()
        .map_err(|_| format!("failed to parse int32 from tag: {}", tag))
}

pub fn get_int64(node: &roxmltree::Node, tag: &str) -> Result<i64, String> {
    let text = get_string(node, tag)?;
    text.parse::<i64>()
        .map_err(|_| format!("failed to parse int64 from tag: {}", tag))
}

pub fn get_bool(node: &roxmltree::Node, tag: &str) -> Result<bool, String> {
    let text = get_string(node, tag)?;
    match text.to_uppercase().as_str() {
        "1" | "Y" | "TRUE" => Ok(true),
        "0" | "N" | "FALSE" => Ok(false),
        _ => Err(format!("failed to parse bool from tag: {}", tag)),
    }
}

pub fn get_ints(node: &roxmltree::Node, tag: &str) -> Vec<i32> {
    node.children()
        .filter(|node| node.has_tag_name(tag))
        .filter_map(|node| node.text())
        .flat_map(|text| text.split(',').filter_map(|s| s.trim().parse::<i32>().ok()))
        .collect()
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
