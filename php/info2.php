<?php
require('routeros_api.class.php');

$iphost = "192.168.99.1";
$userhost = "admin";
$passwdhost = "fausin1989";
$api_puerto = 8728;
$interface = 'TIS_JKT';

$API = new RouterosAPI();
$API->debug = false;

if ($API->connect($iphost, $userhost, $passwdhost)) {
    $getinterfacetraffic = $API->comm("/interface/monitor-traffic", array(
        "interface" => "$interface",
        "once" => "",
    ));

    $download = $getinterfacetraffic[0]['rx-bits-per-second'];

    $result = round($download / 1024 / 1024, 2); // Konversi ke MB dan membulatkannya
} else {
    $result = array(
        "error" => "Connection Failed!!"
    );
}

$API->disconnect();

print json_encode($result);
?>
