<?php
// Generate PHP literals safely; credentials can contain quotes/backslashes.
function envValue(string $name, string $fallback = ''): string {
    $value=getenv($name); return $value === false ? $fallback : $value;
}
function writeConfig(string $file, string $text): void {
    if (file_put_contents($file, $text) === false) { throw new RuntimeException('Cannot write configuration'); }
    if (!chgrp($file, 'www-data') || !chmod($file, 0640)) { throw new RuntimeException('Cannot protect configuration'); }
}
$url=envValue('BASE_URL');
if (!filter_var($url, FILTER_VALIDATE_URL) || !in_array(parse_url($url,PHP_URL_SCHEME), ['http','https'],true)) {
    throw new RuntimeException('Invalid BASE_URL');
}
$key=envValue('ENCRYPTION_KEY');
if (!preg_match('/^[a-f0-9]{64}$/', $key) || strlen(envValue('DB_PASSWORD'))<24) {
    throw new RuntimeException('Generate valid .env secrets before starting');
}
$values=['BASE_URL'=>rtrim($url,'/'), 'LANGUAGE'=>'spanish', 'DEBUG_MODE'=>false,
'DB_HOST'=>'db','DB_NAME'=>'easyappointments','DB_USERNAME'=>'hefesto_agenda',
'DB_PASSWORD'=>envValue('DB_PASSWORD'), 'GOOGLE_SYNC_FEATURE'=>false,
'GOOGLE_CLIENT_ID'=>'','GOOGLE_CLIENT_SECRET'=>''];
$text="<?php\nclass Config {\n";
foreach($values as $name=>$value) {$text.='const '.$name.' = '.var_export($value,true).";\n";}
writeConfig('/var/www/html/config.php', $text."}\n");
$mail=['useragent'=>'Hefesto Agenda','protocol'=>'smtp','mailtype'=>'html',
'smtp_debug'=>0,'smtp_auth'=>envValue('MAIL_SMTP_AUTH','0')==='1',
'smtp_host'=>envValue('MAIL_SMTP_HOST','127.0.0.1'),'smtp_user'=>envValue('MAIL_SMTP_USER'),
'smtp_pass'=>envValue('MAIL_SMTP_PASS'),'smtp_crypto'=>envValue('MAIL_SMTP_CRYPTO'),
'smtp_port'=>(int)envValue('MAIL_SMTP_PORT','2525'),
'from_name'=>envValue('MAIL_FROM_NAME','Hefesto Agenda'),'from_address'=>envValue('MAIL_FROM_ADDRESS','agenda@example.invalid'),
'reply_to'=>envValue('MAIL_FROM_ADDRESS','agenda@example.invalid'),'crlf'=>"\r\n",'newline'=>"\r\n"];
$text="<?php defined('BASEPATH') or exit('No direct script access allowed');\n";
foreach($mail as $name=>$value){$text.='$config['.var_export($name,true).'] = '.var_export($value,true).";\n";}
writeConfig('/var/www/html/application/config/email.php',$text);
$base=file_get_contents('/opt/hefesto/config-base.php');
if ($base===false) {throw new RuntimeException('Missing base config');}
$base.="\n// Hefesto: canonical URL and persistent instance encryption key.\n";
$base.='$config["base_url"] = Config::BASE_URL;' . "\n";
$base.='$config["cookie_secure"] = '.var_export(parse_url($url,PHP_URL_SCHEME)==='https',true).";\n";
$base.='$config["encryption_key"] = '.var_export($key,true).";\n";
writeConfig('/var/www/html/application/config/config.php',$base);
file_put_contents('/usr/local/etc/php/conf.d/hefesto.ini',"date.timezone=America/Santiago\nxdebug.mode=off\n");
