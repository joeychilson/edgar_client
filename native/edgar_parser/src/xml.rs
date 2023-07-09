use rustler::NifUntaggedEnum;

#[derive(NifUntaggedEnum)]
pub enum Value {
    Int(i64),
    Float(f64),
    Text(String),
    Bool(bool),
}

pub fn get_string(tag: &str, node: &roxmltree::Node) -> Option<String> {
    node.children()
        .find(|node| node.has_tag_name(tag))
        .and_then(|node| node.text())
        .map(|s| s.to_string())
}

pub fn get_bool(tag: &str, node: &roxmltree::Node) -> Option<bool> {
    get_string(tag, node)
        .map(|text| text == "1")
        .or(Some(false))
}

pub fn get_value(tag: &str, node: &roxmltree::Node) -> Option<Value> {
    node.children()
        .find(|node| node.has_tag_name(tag))
        .and_then(|tag_node| {
            tag_node
                .children()
                .find(|child_node| child_node.has_tag_name("value"))
                .and_then(|value_node| value_node.text())
                .map(|s| s.to_string())
        })
        .map(parse_value)
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
