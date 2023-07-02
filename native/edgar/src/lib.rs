mod thirteenf;

use thirteenf::{parse_13f_document, parse_13f_table};

rustler::init!("Elixir.EDGAR.Native", [parse_13f_document, parse_13f_table]);
