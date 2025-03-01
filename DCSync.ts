import { createLdapClient, LdapClient } from 'ldapjs';
import { promisify } from 'util';

async function dcsync(domain: string, username: string, password: string, targetUser: string): Promise<void> {
    const ldapUrl = `ldap://${domain}`;
    const ldapClient: LdapClient = createLdapClient({
        url: ldapUrl,
        bindDN: `${domain}\\${username}`,
        bindCredentials: password,
    });

    const search = promisify(ldapClient.search).bind(ldapClient);

    try {
        await ldapClient.bind();

        const searchFilter = `(samaccountname=${targetUser})`;
        const searchOptions = {
            scope: 'sub',
            filter: searchFilter,
            attributes: ['samaccountname', 'useraccountcontrol', 'pwdlastset', 'lastlogontimestamp'],
        };

        const searchResult = await search('', searchOptions);

        if (searchResult.entries.length > 0) {
            const userEntry = searchResult.entries[0];
            const userData = {
                samaccountname: userEntry.getAttributeValue('samaccountname'),
                useraccountcontrol: userEntry.getAttributeValue('useraccountcontrol'),
                pwdlastset: userEntry.getAttributeValue('pwdlastset'),
                lastlogontimestamp: userEntry.getAttributeValue('lastlogontimestamp'),
            };
            console.log(JSON.stringify(userData, null, 2));
        } else {
            console.log('User not found.');
        }
    } catch (error) {
        console.error('Error:', error);
    } finally {
        ldapClient.unbind();
    }
}

const [domain, username, password, targetUser] = process.argv.slice(2);

if (process.argv.length !== 5) {
    console.log('Usage: ts-node dcsync.ts <domain> <username> <password> <target_user>');
    process.exit(1);
}

dcsync(domain, username, password, targetUser);
