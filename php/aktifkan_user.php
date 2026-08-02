<?php
header('Content-Type: application/json');
include "kon.php";
require('routeros_api.class.php');

// Get parameters from GET
$username = isset($_GET['username']) ? $_GET['username'] : '';
$profile = isset($_GET['profile']) ? $_GET['profile'] : '';

if (empty($username)) {
    echo json_encode([
        'success' => false,
        'message' => 'Username tidak boleh kosong'
    ]);
    exit;
}

if (empty($profile)) {
    echo json_encode([
        'success' => false,
        'message' => 'Profile tidak boleh kosong'
    ]);
    exit;
}

$API = new RouterosAPI();
$API->debug = false;

// Connect to MikroTik router
if ($API->connect('192.168.99.182', 'admin', 'fausin1989')) {
    try {
        // Find the user in PPP secrets
        $API->write('/ppp/secret/print', false);
        $API->write('?name=' . $username);
        $secretData = $API->read();
        
        if (empty($secretData)) {
            echo json_encode([
                'success' => false,
                'message' => 'User tidak ditemukan'
            ]);
            $API->disconnect();
            exit;
        }
        
        $secretId = $secretData[0]['.id'];
        
        // Update profile back to original
        $API->write('/ppp/secret/set', false);
        $API->write('=.id=' . $secretId, false);
        $API->write('=profile=' . $profile);
        $API->read();
        
        // Disconnect active session if any (to force reconnect with new profile)
        $API->write('/ppp/active/print', false);
        $API->write('?name=' . $username);
        $activeData = $API->read();
        
        if (!empty($activeData)) {
            $activeId = $activeData[0]['.id'];
            $API->write('/ppp/active/remove', false);
            $API->write('=.id=' . $activeId);
            $API->read();
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'User ' . $username . ' berhasil diaktifkan kembali ke profile ' . $profile
        ]);
        
    } catch (Exception $e) {
        echo json_encode([
            'success' => false,
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
    
    $API->disconnect();
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal koneksi ke MikroTik router'
    ]);
}
?>
