import java.net.URI
import javax.naming.directory.*
import javax.naming.ldap.*
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.*

fun main(args: Array<String>) {
    if (args.size != 5) {
        println("Usage: DCSync.kt <domain> <username> <password> <target_user>")
        return
    }

    val domain = args[0]
    val username = args[1]
    val password = args[2]
    val targetUser = args[3]

    val ldapUrl = "ldap://$domain"
    val ldapEnv = mutableMapOf<String, Any>(
        Context.INITIAL_CONTEXT_FACTORY to "com.sun.jndi.ldap.LdapCtxFactory",
        Context.PROVIDER_URL to ldapUrl,
        Context.SECURITY_AUTHENTICATION to "simple",
        Context.SECURITY_PRINCIPAL to "$domain\\$username",
        Context.SECURITY_CREDENTIALS to password
    )

    val ctx = InitialDirContext(ldapEnv)

    val searchFilter = "(samaccountname=$targetUser)"
    val searchControls = SearchControls()
    searchControls.searchScope = SearchControls.SUBTREE_SCOPE
    searchControls.returningAttributes = arrayOf("samaccountname", "useraccountcontrol", "pwdlastset", "lastlogontimestamp")

    val searchResult = ctx.search("DC=${domain.split(".")[0]},DC=${domain.split(".")[1]}", searchFilter, searchControls)

    if (searchResult.hasMore()) {
        val userEntry = searchResult.next() as Attributes
        val userData = mapOf(
            "samaccountname" to userEntry.get("samaccountname").toString(),
            "useraccountcontrol" to userEntry.get("useraccountcontrol").toString(),
            "pwdlastset" to userEntry.get("pwdlastset").toString(),
            "lastlogontimestamp" to userEntry.get("lastlogontimestamp").toString()
        )
        val mapper = jacksonObjectMapper()
        val userDataJson = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(userData)
        println(userDataJson)
    } else {
        println("User not found.")
    }

    ctx.close()
}
