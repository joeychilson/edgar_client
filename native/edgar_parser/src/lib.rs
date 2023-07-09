mod company_feed;
mod current_feed;
mod form13;
mod form4;
mod xbrl;
mod xml;

use company_feed::parse_company_feed;
use current_feed::parse_current_feed;
use form13::{parse_form13_document, parse_form13_table};
use form4::parse_form4;
use xbrl::parse_xbrl;

rustler::init!(
    "Elixir.EDGAR.Native",
    [
        parse_company_feed,
        parse_current_feed,
        parse_form4,
        parse_form13_document,
        parse_form13_table,
        parse_xbrl,
    ]
);
