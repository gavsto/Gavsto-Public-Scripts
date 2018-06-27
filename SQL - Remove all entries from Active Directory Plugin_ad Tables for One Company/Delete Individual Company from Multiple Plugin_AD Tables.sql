DELETE FROM plugin_ad_userproxyaddresses WHERE objectguid IN (SELECT objectguid FROM plugin_ad_users WHERE plugin_ad_users.objectguid IN (SELECT objectguid FROM plugin_ad_entries WHERE DomainGuid = '7e9d725b-a04d-4bb7-9403-b3fa28e4ba8c'));
DELETE FROM plugin_ad_memberofxrefs WHERE objectguid IN (SELECT objectguid FROM plugin_ad_users WHERE plugin_ad_users.objectguid IN (SELECT objectguid FROM plugin_ad_entries WHERE DomainGuid = '7e9d725b-a04d-4bb7-9403-b3fa28e4ba8c'));
DELETE FROM plugin_ad_users WHERE plugin_ad_users.objectguid IN (SELECT objectguid FROM plugin_ad_entries WHERE DomainGuid = '7e9d725b-a04d-4bb7-9403-b3fa28e4ba8c');
DELETE FROM plugin_ad_computers WHERE plugin_ad_computers.objectguid IN (SELECT objectguid FROM plugin_ad_entries WHERE DomainGuid = '7e9d725b-a04d-4bb7-9403-b3fa28e4ba8c');
DELETE FROM plugin_ad_entries WHERE DomainGuid = '7e9d725b-a04d-4bb7-9403-b3fa28e4ba8c';


