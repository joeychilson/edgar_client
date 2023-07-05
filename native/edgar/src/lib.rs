mod form13;
mod form4;

use form13::{parse_form13_document, parse_form13_table};
use form4::parse_form4;

rustler::init!(
    "Elixir.EDGAR.Native",
    [parse_form4, parse_form13_document, parse_form13_table,]
);
