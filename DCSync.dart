import 'dart:io';
import 'dart:convert';
import 'package:ldap_client/ldap_client.dart';

void main(List<String> args) async {
  if (args.length != 5) {
    print('Usage: dart dcsync.dart <domain> <username> <password> <target_user>');
    exit(1);
  }

  final domain = args[0];
  final username = args[1];
  final password = args[2];
  final targetUser = args[3];

  final ldapUrl = 'ldap://$domain';
  final ldapConn = LDAPConnection(ldapUrl, username: '$domain\\$username', password: password);
  await ldapConn.open();

  final searchFilter = '(samaccountname=$targetUser)';
  final searchResult = await ldapConn.search(
    baseDN: 'DC=${domain.split(".")[0]},DC=${domain.split(".")[1]}',
    filter: searchFilter,
    attributes: ['samaccountname', 'useraccountcontrol', 'pwdlastset', 'lastlogontimestamp'],
  );

  if (searchResult.entries.isNotEmpty) {
    final userEntry = searchResult.entries.first;
    final userData = {
      'samaccountname': userEntry.attributes['samaccountname'].first,
      'useraccountcontrol': userEntry.attributes['useraccountcontrol'].first,
      'pwdlastset': userEntry.attributes['pwdlastset'].first,
      'lastlogontimestamp': userEntry.attributes['lastlogontimestamp'].first,
    };
    final userDataJson = jsonEncode(userData, prettyPrint: true);
    print(userDataJson);
  } else {
    print('User not found.');
  }

  await ldapConn.close();
}
