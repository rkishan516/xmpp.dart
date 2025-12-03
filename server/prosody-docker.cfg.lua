-- Prosody Configuration for Docker
-- For testing xmpp.dart

modules_enabled = {
    "roster";
    "saslauth";
    "tls";
    "disco";
    "ping";
    "register";
    "bosh";
    "websocket";
    "time";
    "version";
    "smacks";
    "carbons";
    "pep";
    "blocklist";
};

modules_disabled = {
    "s2s";
}

allow_registration = true;
allow_unencrypted_plain_auth = true;
c2s_require_encryption = false;

consider_websocket_secure = true;
consider_bosh_secure = true;
cross_domain_bosh = true;
cross_domain_websocket = true;

authentication = "internal_plain"

log = {
    info = "*console";
    error = "*console";
}

VirtualHost "localhost"

Component "component.localhost"
    component_secret = "mysecretcomponentpassword"

VirtualHost "anon.localhost"
    authentication = "anonymous"
