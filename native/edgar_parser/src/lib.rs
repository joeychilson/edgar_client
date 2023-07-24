mod feeds;
mod ownership;
mod thirteenf;
mod xbrl;
mod xml;

use feeds::{parse_company_feed, parse_current_feed, parse_rss_feed, parse_xbrl_feed};
use ownership::parse_ownership_form;
use thirteenf::{parse_form13f_document, parse_form13f_table};
use xbrl::parse_xbrl;

rustler::init!(
    "Elixir.EDGAR.Native",
    [
        parse_company_feed,
        parse_current_feed,
        parse_form13f_document,
        parse_form13f_table,
        parse_ownership_form,
        parse_rss_feed,
        parse_xbrl,
        parse_xbrl_feed,
    ]
);
