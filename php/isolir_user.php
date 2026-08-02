<?php
header('Content-Type: application/json');
include "kon.php";
require('routeros_api.class.php');

// Get username from GET parameter
$username = isset($_GET['username']) ? $_GET['username'] : '';

if (empty($username)) {
    echo json_encode([
        'success' => false,
        'message' => 'Username tidak boleh kosong'
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
        $currentProfile = isset($secretData[0]['profile']) ? $secretData[0]['profile'] : '';
        $currentComment = isset($secretData[0]['comment']) ? $secretData[0]['comment'] : '';
        
        // Check if already isolated
        if ($currentProfile === 'ISOLIR') {
            echo json_encode([
                'success' => false,
                'message' => 'User sudah dalam status isolir'
            ]);
            $API->disconnect();
            exit;
        }
        
        // Save original profile in comment before isolating
        $newComment = 'ORIGINAL_PROFILE:' . $currentProfile;
        if (!empty($currentComment)) {
            $newComment .= '|' . $currentComment;
        }
        
        // Update profile to ISOLIR and save original profile in comment
        $API->write('/ppp/secret/set', false);
        $API->write('=.id=' . $secretId, false);
        $API->write('=profile=ISOLIR', false);
        $API->write('=comment=' . $newComment);
        $API->read();
        
        // Disconnect active session if any
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
            'message' => 'User ' . $username . ' berhasil diisolir'
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
