package main

import (
    "encoding/json"
    "fmt"
    "os"
    "github.com/go-ldap/ldap/v3"
)

func dcsyncgo(domain, username, password, targetUser string) {
    ldapURL := fmt.Sprintf("ldap://%s", domain)
    ldapConn, err := ldap.DialURL(ldapURL)
    if err != nil {
        fmt.Println("Error creating LDAP connection:", err)
        return
    }
    defer ldapConn.Close()

    err = ldapConn.Bind(fmt.Sprintf("%s\\%s", domain, username), password)
    if err != nil {
        fmt.Println("Error binding to LDAP server:", err)
        return
    }

    searchFilter := fmt.Sprintf("(samaccountname=%s)", targetUser)
    searchRequest := ldap.NewSearchRequest(
        fmt.Sprintf("DC=%s,DC=%s", domain, domain),
        ldap.ScopeWholeSubtree, ldap.NeverDerefAliases, 0, 0, false,
        searchFilter,
        []string{"samaccountname", "useraccountcontrol", "pwdlastset", "lastlogontimestamp"},
        nil,
    )

    searchResult, err := ldapConn.Search(searchRequest)
    if err != nil {
        fmt.Println("Error performing LDAP search:", err)
        return
    }

    if len(searchResult.Entries) > 0 {
        userEntry := searchResult.Entries[0]
        userData := map[string]string{
            "samaccountname":     userEntry.GetAttributeValue("samaccountname"),
            "useraccountcontrol": userEntry.GetAttributeValue("useraccountcontrol"),
            "pwdlastset":         userEntry.GetAttributeValue("pwdlastset"),
            "lastlogontimestamp": userEntry.GetAttributeValue("lastlogontimestamp"),
        }
        userDataJSON, err := json.MarshalIndent(userData, "", "  ")
        if err != nil {
            fmt.Println("Error marshaling user data to JSON:", err)
            return
        }
        fmt.Println(string(userDataJSON))
    } else {
        fmt.Println("User not found.")
    }
}

func main() {
    if len(os.Args) != 5 {
        fmt.Println("Usage: go run dcsync.go <domain> <username> <password> <target_user>")
        os.Exit(1)
    }

    domain := os.Args[1]
    username := os.Args[2]
    password := os.Args[3]
    targetUser := os.Args[4]

    dcsyncgo(domain, username, password, targetUser)
}
