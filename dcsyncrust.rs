use ldap3::{LdapConn, Scope, SearchEntry};
use serde_json::json;
use std::env;

fn dcsyncrust(domain: &str, username: &str, password: &str, target_user: &str) {
    let ldap_url = format!("ldap://{}", domain);
    let mut ldap_conn = LdapConn::new(&ldap_url).unwrap();
    ldap_conn.simple_bind(format!("{}\\{}", domain, username), password).unwrap();

    let search_filter = format!("(samaccountname={})", target_user);
    let search_result = ldap_conn
        .search(
            SearchEntry::new(format!("DC={}", domain))
                .base_object()
                .one_level()
                .filter(&search_filter)
                .attributes(vec![
                    "samaccountname",
                    "useraccountcontrol",
                    "pwdlastset",
                    "lastlogontimestamp",
                ]),
        )
        .unwrap();

    if let Some(user_entry) = search_result.unwrap().next() {
        let user_data = json::json![{
            "samaccountname": user_entry.get_value("samaccountname").unwrap(),
            "useraccountcontrol": user_entry.get_value("useraccountcontrol").unwrap(),
            "pwdlastset": user_entry.get_value("pwdlastset").unwrap(),
            "lastlogontimestamp": user_entry.get_value("lastlogontimestamp").unwrap(),
        }];
        println!("{}", user_data.to_string());
    } else {
        println!("User not found.");
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 5 {
        println!("Usage: cargo run -- <domain> <username> <password> <target_user>");
        return;
    }

    let domain = &args[1];
    let username = &args[2];
    let password = &args[3];
    let target_user = &args[4];

    dcsyncrust(domain, username, password, target_user);
}
