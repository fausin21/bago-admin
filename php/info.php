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

    $rows = array();
    $rows2 = array();

    $ftx = $getinterfacetraffic[0]['tx-bits-per-second'];
    $frx = $getinterfacetraffic[0]['rx-bits-per-second'];

     $rows['data'][] = round($ftx / 1024 / 1024, 2); // Konversi ke MB dan membulatkannya
       $rows2['data'][] = round($frx / 1024 / 1024, 2); // Konversi ke MB dan membulatkannya

} else {
    echo "Connection Failed!!";
}

$API->disconnect();

$result = array();

array_push($result, $rows);
array_push($result, $rows2);

print json_encode($result);
?>
