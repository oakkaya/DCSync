using LDAPClient
using JSON

function dcsync(domain::String, username::String, password::String, target_user::String)
    ldap_url = "ldap://$domain"
    ldap_conn = LDAPClient.Connection(ldap_url, username="$domain\\$username", password=password)

    search_filter = "(samaccountname=$target_user)"
    search_result = LDAPClient.search(ldap_conn, "DC=$(split(domain, '.')[1]),DC=$(split(domain, '.')[2])", search_filter, ["samaccountname", "useraccountcontrol", "pwdlastset", "lastlogontimestamp"])

    if length(search_result) > 0
        user_entry = search_result[1]
        user_data = Dict(
            "samaccountname" => user_entry["samaccountname"][1],
            "useraccountcontrol" => user_entry["useraccountcontrol"][1],
            "pwdlastset" => user_entry["pwdlastset"][1],
            "lastlogontimestamp" => user_entry["lastlogontimestamp"][1]
        )
        user_data_json = JSON.json(user_data, 2)
        println(user_data_json)
    else
        println("User not found.")
    end

    LDAPClient.close(ldap_conn)
end

if length(ARGS) != 4
    println("Usage: julia dcsync.jl <domain> <username> <password> <target_user>")
    exit(1)
end

domain = ARGS[1]
username = ARGS[2]
password = ARGS[3]
target_user = ARGS[4]

dcsync(domain, username, password, target_user)
