<?php
require('routeros_api.class.php');

// Informasi mikrotik
$mikrotiks = array(
    array(
        "ip" => "192.168.99.1", 
        "user" => "admin",
        "pass" => "fausin1989",
        "interface" => "INT",
        "ping_host" => "8.8.8.8" // Host untuk ping test
    )
);

$result = array();

$API = new RouterosAPI();
$API->debug = false;

foreach ($mikrotiks as $mikrotik) {
    if ($API->connect($mikrotik['ip'], $mikrotik['user'], $mikrotik['pass'])) {
        // Get interface traffic
        $getinterfacetraffic = $API->comm("/interface/monitor-traffic", array(
            "interface" => $mikrotik['interface'],
            "once" => "",
        ));

        // Get ping results with more details
        $ping_result = $API->comm("/ping", array(
            "address" => $mikrotik['ping_host'],
            "count" => "5",
            "size" => "64" // Packet size in bytes
        ));

        // Convert traffic values to float to avoid numeric warnings
        $ftx = floatval($getinterfacetraffic[0]['tx-bits-per-second']);
        $frx = floatval($getinterfacetraffic[0]['rx-bits-per-second']);

        $tx_speed = round($ftx / 1024 / 1024, 2); // Konversi ke MB
        $rx_speed = round($frx / 1024 / 1024, 2); // Konversi ke MB

        // Calculate detailed ping statistics
        $total_time = 0;
        $packet_loss = 0;
        $min_latency = PHP_FLOAT_MAX;
        $max_latency = 0;
        $successful_pings = array();

        foreach ($ping_result as $ping) {
            if (isset($ping['time'])) {
                $time = floatval($ping['time']);
                $total_time += $time;
                $successful_pings[] = $time;
                $min_latency = min($min_latency, $time);
                $max_latency = max($max_latency, $time);
            } else {
                $packet_loss++;
            }
        }

        $ping_count = count($ping_result);
        $successful_count = count($successful_pings);
        
        $avg_latency = $successful_count > 0 ? round($total_time / $successful_count, 2) : 0;
        $packet_loss_percent = round(($packet_loss / $ping_count) * 100, 2);
        
        // Calculate jitter (latency variation)
        $jitter = 0;
        if (count($successful_pings) > 1) {
            $differences = array();
            for ($i = 1; $i < count($successful_pings); $i++) {
                $differences[] = abs($successful_pings[$i] - $successful_pings[$i-1]);
            }
            $jitter = round(array_sum($differences) / count($differences), 2);
        }

        $result[] = array(
            "ip" => $mikrotik['ip'],
            "tx_speed" => $tx_speed,
            "rx_speed" => $rx_speed,
            "ping_stats" => array(
                "avg_latency" => $avg_latency,
                "min_latency" => $min_latency === PHP_FLOAT_MAX ? 0 : round($min_latency, 2),
                "max_latency" => round($max_latency, 2),
                "jitter" => $jitter,
                "packet_loss" => $packet_loss_percent,
                "packets_sent" => $ping_count,
                "packets_received" => $successful_count
            ),
            "ping_host" => $mikrotik['ping_host']
        );

        $API->disconnect();
    } else {
        $result[] = array(
            "ip" => $mikrotik['ip'],
            "error" => "Connection failed"
        );
    }
}

header('Content-Type: application/json');
echo json_encode($result);
?>
