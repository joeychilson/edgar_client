mod form4;
mod thirteenf;

use form4::parse_form4;
use thirteenf::{parse_13f_document, parse_13f_table};

rustler::init!(
    "Elixir.EDGAR.Native",
    [parse_form4, parse_13f_document, parse_13f_table,]
);
