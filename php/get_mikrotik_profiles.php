<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

include "connection.php";
require('routeros_api.class.php');

try {
    $id_mikrotik = isset($_GET['id_mikrotik']) ? (int)$_GET['id_mikrotik'] : 0;
    
    if ($id_mikrotik <= 0) {
        echo json_encode(['success' => false, 'message' => 'ID Mikrotik tidak valid', 'profiles' => []]);
        exit;
    }
    
    // Ambil data Mikrotik dari database
    $rsMikrotik = mysqli_query($connection, "SELECT ip, port, user, pass FROM mikrotik WHERE id = $id_mikrotik LIMIT 1");
    
    if (!$rsMikrotik || mysqli_num_rows($rsMikrotik) == 0) {
        echo json_encode(['success' => false, 'message' => 'Mikrotik tidak ditemukan', 'profiles' => []]);
        exit;
    }
    
    $mtk = mysqli_fetch_assoc($rsMikrotik);
    
    // Hubungkan ke Mikrotik dan ambil profile
    $profiles = [];
    $API = new RouterosAPI();
    $ip = $mtk['ip'];
    $port = !empty($mtk['port']) ? (int)$mtk['port'] : 8728;
    $user = $mtk['user'];
    $pass = $mtk['pass'];
    
    if ($API->connect($ip, $user, $pass, $port)) {
        $result = $API->comm('/ppp/profile/print');
        if ($result && is_array($result)) {
            foreach ($result as $pr) {
                if (!empty($pr['name'])) {
                    $profiles[] = $pr['name'];
                }
            }
        }
        $API->disconnect();
        echo json_encode(['success' => true, 'profiles' => $profiles]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal terhubung ke Mikrotik', 'profiles' => []]);
    }
    
} catch (\Throwable $th) {
    echo json_encode(['success' => false, 'message' => $th->getMessage(), 'profiles' => []]);
}
?>
