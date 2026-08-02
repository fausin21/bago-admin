<?php

require('routeros_api.class.php');
include "kon.php";
$API = new RouterosAPI();
$data = array();

// Define router configurations
$routers = array(
    array('ip' => '192.168.99.198', 'username' => 'admin', 'password' => 'fausin1989', 'location' => 'mandati'),
    array('ip' => '192.168.99.243', 'username' => 'admin', 'password' => 'fausin1989', 'location' => 'bago_sentul'),
    array('ip' => '192.168.99.241', 'username' => 'fausin', 'password' => 'ahmadqois', 'location' => 'kds'),
    array('ip' => '192.168.99.244', 'username' => 'fausin', 'password' => 'ahmadqois', 'location' => 'ranon'),
    array('ip' => '192.168.99.242', 'username' => 'fausin', 'password' => 'ahmadqqois', 'location' => 'rabunan'),
    array('ip' => '192.168.99.197', 'username' => 'admin', 'password' => 'fausin1989', 'location' => 'plaosan'),
);

// Ambil semua user dari database sekali saja untuk menghindari query berulang
$query = "SELECT id, username, password, cabang FROM usuarios";
$result = mysqli_query($koneksi, $query);

if ($result) {
    // Buat array untuk lookup user yang lebih cepat
    $usuarios_lookup = array();
    while ($row = mysqli_fetch_array($result)) {
        $usuarios_lookup[$row['username']] = array(
            'username' => $row['username'],
            'password' => $row['password'],
            'cabang' => $row['cabang']
        );
    }
    
    $API->debug = false;
    
    // Loop through each router dengan timeout yang lebih pendek
    foreach ($routers as $router) {
        // Set timeout koneksi lebih pendek untuk mempercepat
        if ($API->connect($router['ip'], $router['username'], $router['password'], 3)) {
            $getuser = $API->comm("/ip/hotspot/active/print", array(
                "?server" => "hotspot1",
            ));

            foreach ($getuser as $user) {
                // Gunakan lookup array instead of database query
                if (isset($usuarios_lookup[$user['user']])) {
                    $row = $usuarios_lookup[$user['user']];
                    $uptime = $user['uptime'];

                    // Optimasi parsing uptime
                    if (preg_match('/(\d+)h/', $uptime, $matches)) {
                        $hours = (int)$matches[1];
                        $uptime = $hours >= 1 ? $hours . 'h' : '';
                    } else if (preg_match('/(\d+)m/', $uptime, $matches)) {
                        $minutes = (int)$matches[1];
                        $uptime = $minutes < 60 ? $minutes . 'm' : '';
                    }

                    $data[] = array(
                        'user' => $row['username'],
                        'cabang' => $row['cabang'],
                        'status' => $uptime,
                        'location' => $router['location']
                    );
                }
            }
            $API->disconnect();
        } else {
            // Log koneksi gagal tapi lanjutkan ke router berikutnya
            error_log("Failed to connect to router: " . $router['ip']);
        }
    }

    // Set header untuk JSON dan cache
    header('Content-Type: application/json');
    header('Cache-Control: max-age=30'); // Cache 30 detik
    echo json_encode($data);
} else {
    header('Content-Type: application/json');
    echo json_encode(array('error' => 'Database query failed: ' . mysqli_error($koneksi)));
}

?>
