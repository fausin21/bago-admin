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
        
        // Check if user is currently isolated
        if (strtoupper($currentProfile) === 'ISOLIR') {
            // ACTIVATE USER - Restore original profile
            
            // Extract original profile from comment
            $originalProfile = '';
            if (strpos($currentComment, 'ORIGINAL_PROFILE:') !== false) {
                preg_match('/ORIGINAL_PROFILE:([^|]+)/', $currentComment, $matches);
                if (isset($matches[1])) {
                    $originalProfile = trim($matches[1]);
                }
                
                // Remove original profile info from comment
                $newComment = preg_replace('/ORIGINAL_PROFILE:[^|]+\|?/', '', $currentComment);
                $newComment = trim($newComment);
            }
            
            if (empty($originalProfile)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Profile original tidak ditemukan. Silakan set manual.'
                ]);
                $API->disconnect();
                exit;
            }
            
            // Update profile back to original
            $API->write('/ppp/secret/set', false);
            $API->write('=.id=' . $secretId, false);
            if (!empty($newComment)) {
                $API->write('=comment=' . $newComment, false);
            } else {
                $API->write('=comment=', false);
            }
            $API->write('=profile=' . $originalProfile);
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
                'message' => 'User ' . $username . ' berhasil diaktifkan kembali ke profile ' . $originalProfile,
                'action' => 'activated',
                'profile' => $originalProfile
            ]);
            
        } else {
            // ISOLATE USER - Save current profile and switch to ISOLIR
            
            // Save original profile in comment
            $newComment = 'ORIGINAL_PROFILE:' . $currentProfile;
            if (!empty($currentComment)) {
                // Remove any existing ORIGINAL_PROFILE entry first
                $currentComment = preg_replace('/ORIGINAL_PROFILE:[^|]+\|?/', '', $currentComment);
                $currentComment = trim($currentComment);
                if (!empty($currentComment)) {
                    $newComment .= '|' . $currentComment;
                }
            }
            
            // Update profile to ISOLIR
            $API->write('/ppp/secret/set', false);
            $API->write('=.id=' . $secretId, false);
            $API->write('=comment=' . $newComment, false);
            $API->write('=profile=ISOLIR');
            $API->read();
            
            // Disconnect active session
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
                'message' => 'User ' . $username . ' berhasil diisolir',
                'action' => 'isolated',
                'original_profile' => $currentProfile
            ]);
        }
        
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
