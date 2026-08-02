<?php
/**
 * Auto Isolir Cron Script
 * 
 * Dipanggil otomatis tiap bulan oleh MikroTik scheduler atau cron job.
 * Cek semua pelanggan yang punya auto_isolir = 1,
 * jika belum bayar bulan ini → isolir di MikroTik.
 * 
 * URL: http://aplikasi.bago.web.id/api/admin/auto_isolir_cron.php
 * Optional: ?force=1 (paksa jalankan walaupun bukan tanggal isolir)
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

include "connection.php";
require_once('routeros_api.class.php');

$force = isset($_GET['force']) ? (int)$_GET['force'] : 0;
$today = (int)date('j'); // Tanggal hari ini (1-31)
$bulan_ini = date('n');  // Bulan sekarang (1-12)
$tahun_ini = date('Y');  // Tahun sekarang

$response = [
    'success' => true,
    'tanggal' => date('Y-m-d H:i:s'),
    'total_checked' => 0,
    'total_isolir' => 0,
    'total_skip_lunas' => 0,
    'total_skip_already_isolir' => 0,
    'total_error' => 0,
    'details' => []
];

try {
    // 1. Ambil semua pelanggan yang auto_isolir = 1
    // Filter berdasarkan tanggal isolir (tgl_auto_isolir) kecuali force=1
    if ($force) {
        $query = "SELECT p.id_pelanggan, p.nama, p.auto_isolir, p.tgl_auto_isolir, p.id_mikrotik
                  FROM tb_pelanggan p 
                  WHERE p.auto_isolir = 1";
    } else {
        $query = "SELECT p.id_pelanggan, p.nama, p.auto_isolir, p.tgl_auto_isolir, p.id_mikrotik
                  FROM tb_pelanggan p 
                  WHERE p.auto_isolir = 1 
                  AND p.tgl_auto_isolir = $today";
    }
    
    $result = mysqli_query($connection3, $query);
    
    if (!$result) {
        throw new Exception('Query error: ' . mysqli_error($connection3));
    }
    
    $pelanggan_list = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $pelanggan_list[] = $row;
    }
    
    $response['total_checked'] = count($pelanggan_list);
    
    if (empty($pelanggan_list)) {
        $response['message'] = 'Tidak ada pelanggan dengan auto_isolir aktif' . ($force ? '' : ' untuk tanggal ' . $today);
        echo json_encode($response, JSON_PRETTY_PRINT);
        exit;
    }
    
    // 2. Untuk setiap pelanggan, cek apakah sudah bayar bulan ini
    // Group pelanggan by mikrotik untuk efisiensi koneksi
    $mikrotik_groups = [];
    
    foreach ($pelanggan_list as $plg) {
        $id_pelanggan = $plg['id_pelanggan'];
        $nama = $plg['nama'];
        $id_mikrotik = (int)$plg['id_mikrotik'];
        
        // Cek tagihan bulan ini - apakah sudah lunas (LS atau LS_ADMIN)
        $cek_bayar = "SELECT t.id_tagihan, t.status, t.bulan, t.tahun 
                      FROM tb_tagihan t 
                      WHERE t.id_pelanggan = '$id_pelanggan' 
                      AND t.bulan = $bulan_ini 
                      AND t.tahun = $tahun_ini 
                      ORDER BY t.id_tagihan DESC 
                      LIMIT 1";
        
        $result_bayar = mysqli_query($connection3, $cek_bayar);
        $data_bayar = null;
        if ($result_bayar) {
            $data_bayar = mysqli_fetch_assoc($result_bayar);
        }
        
        // Jika sudah bayar (status LS atau LS_ADMIN), skip
        if ($data_bayar && in_array($data_bayar['status'], ['LS', 'LS_ADMIN'])) {
            $response['total_skip_lunas']++;
            $response['details'][] = [
                'nama' => $nama,
                'status' => 'SKIP_LUNAS',
                'message' => 'Sudah lunas bulan ini'
            ];
            continue;
        }
        
        // Belum bayar → tambahkan ke group mikrotik untuk di-isolir
        if (!isset($mikrotik_groups[$id_mikrotik])) {
            $mikrotik_groups[$id_mikrotik] = [];
        }
        $mikrotik_groups[$id_mikrotik][] = $plg;
    }
    
    // 3. Koneksi ke masing-masing MikroTik dan isolir user
    foreach ($mikrotik_groups as $mk_id => $users) {
        // Ambil data MikroTik dari database
        if ($mk_id > 0) {
            $mk_query = mysqli_query($connection, "SELECT ip, port, user, pass FROM mikrotik WHERE id = $mk_id LIMIT 1");
        } else {
            // Default mikrotik
            $mk_query = mysqli_query($connection, "SELECT ip, port, user, pass FROM mikrotik LIMIT 1");
        }
        
        if (!$mk_query || mysqli_num_rows($mk_query) == 0) {
            // Fallback ke IP default
            $mk_ip = '192.168.99.243';
            $mk_port = 8728;
            $mk_user = 'admin';
            $mk_pass = 'fausin1989';
        } else {
            $mk_data = mysqli_fetch_assoc($mk_query);
            $mk_ip = $mk_data['ip'];
            $mk_port = !empty($mk_data['port']) ? (int)$mk_data['port'] : 8728;
            $mk_user = $mk_data['user'];
            $mk_pass = $mk_data['pass'];
        }
        
        $API = new RouterosAPI();
        $API->debug = false;
        
        if (!$API->connect($mk_ip, $mk_user, $mk_pass, $mk_port)) {
            foreach ($users as $u) {
                $response['total_error']++;
                $response['details'][] = [
                    'nama' => $u['nama'],
                    'status' => 'ERROR',
                    'message' => "Gagal koneksi ke MikroTik ($mk_ip)"
                ];
            }
            continue;
        }
        
        foreach ($users as $plg) {
            $username = $plg['nama'];
            
            try {
                // Cari user di PPP secrets
                $API->write('/ppp/secret/print', false);
                $API->write('?name=' . $username);
                $secretData = $API->read();
                
                if (empty($secretData)) {
                    $response['total_error']++;
                    $response['details'][] = [
                        'nama' => $username,
                        'status' => 'ERROR',
                        'message' => 'User tidak ditemukan di MikroTik'
                    ];
                    continue;
                }
                
                $secretId = $secretData[0]['.id'];
                $currentProfile = isset($secretData[0]['profile']) ? $secretData[0]['profile'] : '';
                $currentComment = isset($secretData[0]['comment']) ? $secretData[0]['comment'] : '';
                
                // Sudah di-isolir? Skip
                if (strtoupper($currentProfile) === 'ISOLIR') {
                    $response['total_skip_already_isolir']++;
                    $response['details'][] = [
                        'nama' => $username,
                        'status' => 'SKIP_ALREADY_ISOLIR',
                        'message' => 'Sudah dalam status isolir'
                    ];
                    continue;
                }
                
                // Simpan original profile di comment
                $newComment = 'ORIGINAL_PROFILE:' . $currentProfile;
                if (!empty($currentComment)) {
                    $cleanComment = preg_replace('/ORIGINAL_PROFILE:[^|]+\|?/', '', $currentComment);
                    $cleanComment = trim($cleanComment);
                    if (!empty($cleanComment)) {
                        $newComment .= '|' . $cleanComment;
                    }
                }
                
                // Update profile ke ISOLIR
                $API->write('/ppp/secret/set', false);
                $API->write('=.id=' . $secretId, false);
                $API->write('=profile=ISOLIR', false);
                $API->write('=comment=' . $newComment);
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
                
                $response['total_isolir']++;
                $response['details'][] = [
                    'nama' => $username,
                    'status' => 'ISOLIR_SUCCESS',
                    'message' => "Berhasil di-isolir (profile sebelumnya: $currentProfile)"
                ];
                
            } catch (Exception $e) {
                $response['total_error']++;
                $response['details'][] = [
                    'nama' => $username,
                    'status' => 'ERROR',
                    'message' => $e->getMessage()
                ];
            }
        }
        
        $API->disconnect();
    }
    
    $response['message'] = "Selesai. Isolir: {$response['total_isolir']}, Skip Lunas: {$response['total_skip_lunas']}, Skip Sudah Isolir: {$response['total_skip_already_isolir']}, Error: {$response['total_error']}";
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Error: ' . $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT);

// Close connections
if (isset($connection)) mysqli_close($connection);
if (isset($connection3)) mysqli_close($connection3);
?>
