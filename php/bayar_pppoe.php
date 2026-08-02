<?php
include "../kon.php";
include "connection.php";
require_once('routeros_api.class.php');

$tanggal = date("Y-m-d");

if(isset($_GET['kode'])){
    $sql_cek = "SELECT * FROM tb_tagihan WHERE id_tagihan='".$_GET['kode']."'";
    $query_cek = mysqli_query($koneksi, $sql_cek);
    $data_cek = mysqli_fetch_array($query_cek, MYSQLI_BOTH);
}

// Default status LS, jika admin kirim parameter sts=LS_ADMIN maka pakai LS_ADMIN
if(isset($_GET['sts']) && $_GET['sts'] == 'LS_ADMIN'){
    $status_bayar = 'LS_ADMIN';
} else {
    $status_bayar = 'LS';
}

$sql_ubah = "UPDATE tb_tagihan SET
    status='".$status_bayar."',
    tgl_bayar='".$tanggal."'
    WHERE id_tagihan='".$_GET['kode']."'";
$query_ubah = mysqli_query($koneksi, $sql_ubah);

// === AUTO AKTIFKAN JIKA SEDANG DI-ISOLIR ===
// Ambil data pelanggan dari tagihan yang baru dibayar
if ($query_ubah && isset($data_cek['id_pelanggan'])) {
    $id_plg = $data_cek['id_pelanggan'];
    
    // Ambil nama pelanggan (= username PPPoE)
    $plg_query = mysqli_query($connection3, "SELECT nama, id_mikrotik FROM tb_pelanggan WHERE id_pelanggan = '$id_plg' LIMIT 1");
    
    if ($plg_query && mysqli_num_rows($plg_query) > 0) {
        $plg_data = mysqli_fetch_assoc($plg_query);
        $username = $plg_data['nama'];
        $id_mikrotik = (int)$plg_data['id_mikrotik'];
        
        // Ambil config MikroTik
        if ($id_mikrotik > 0) {
            $mk_query = mysqli_query($connection, "SELECT ip, port, user, pass FROM mikrotik WHERE id = $id_mikrotik LIMIT 1");
        } else {
            $mk_query = mysqli_query($connection, "SELECT ip, port, user, pass FROM mikrotik LIMIT 1");
        }
        
        $mk_ip = '192.168.99.243';
        $mk_port = 8728;
        $mk_user = 'admin';
        $mk_pass = 'fausin1989';
        
        if ($mk_query && mysqli_num_rows($mk_query) > 0) {
            $mk = mysqli_fetch_assoc($mk_query);
            $mk_ip = $mk['ip'];
            $mk_port = !empty($mk['port']) ? (int)$mk['port'] : 8728;
            $mk_user = $mk['user'];
            $mk_pass = $mk['pass'];
        }
        
        // Koneksi ke MikroTik dan cek apakah user sedang di-isolir
        $API = new RouterosAPI();
        $API->debug = false;
        
        if ($API->connect($mk_ip, $mk_user, $mk_pass, $mk_port)) {
            $API->write('/ppp/secret/print', false);
            $API->write('?name=' . $username);
            $secretData = $API->read();
            
            if (!empty($secretData)) {
                $secretId = $secretData[0]['.id'];
                $currentProfile = isset($secretData[0]['profile']) ? $secretData[0]['profile'] : '';
                $currentComment = isset($secretData[0]['comment']) ? $secretData[0]['comment'] : '';
                
                // Jika sedang di-isolir, aktifkan kembali
                if (strtoupper($currentProfile) === 'ISOLIR') {
                    // Extract original profile dari comment
                    $originalProfile = '';
                    if (strpos($currentComment, 'ORIGINAL_PROFILE:') !== false) {
                        preg_match('/ORIGINAL_PROFILE:([^|]+)/', $currentComment, $matches);
                        if (isset($matches[1])) {
                            $originalProfile = trim($matches[1]);
                        }
                        
                        // Bersihkan comment 
                        $newComment = preg_replace('/ORIGINAL_PROFILE:[^|]+\|?/', '', $currentComment);
                        $newComment = trim($newComment);
                    }
                    
                    if (!empty($originalProfile)) {
                        // Kembalikan profile original
                        $API->write('/ppp/secret/set', false);
                        $API->write('=.id=' . $secretId, false);
                        $API->write('=profile=' . $originalProfile, false);
                        if (!empty($newComment)) {
                            $API->write('=comment=' . $newComment);
                        } else {
                            $API->write('=comment=');
                        }
                        $API->read();
                        
                        // Disconnect active session agar reconnect dengan profile baru
                        $API->write('/ppp/active/print', false);
                        $API->write('?name=' . $username);
                        $activeData = $API->read();
                        
                        if (!empty($activeData)) {
                            $activeId = $activeData[0]['.id'];
                            $API->write('/ppp/active/remove', false);
                            $API->write('=.id=' . $activeId);
                            $API->read();
                        }
                    }
                }
            }
            
            $API->disconnect();
        }
    }
}

echo "sukses Update";
?>