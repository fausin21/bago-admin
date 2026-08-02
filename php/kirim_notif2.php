<?php
include "kon.php";
$user = $_GET['user'];

$sts=$_GET['sts'];

$iconUrl = 'http://192.168.99.252/bago.jpg';
// $user_id = $_GET['user_id'];
// $pesan = $_GET['pesan'];
// $title = $_GET['title'];

// cek data ppoe 
 




function sendNotification($deviceToken, $title, $body, $iconUrl) {
    $serverKey = 'AAAAp3xQ4eU:APA91bG4yiFiavsdfXJQsgFIku-t7723V369T7wL5JB1Q6J8Djm3UxFpzBbSlCuHWEDFG-68Mesa69wzZLC7CYDSbn-ByLLYfSsc0bUYFgMNwDclPb-98n0UBWj5AF2V4dwCpdLbOqso'; // Ganti dengan Server Key Anda dari Firebase Console

    $url = 'https://fcm.googleapis.com/fcm/send';

    $headers = array(
        'Authorization: key=' . $serverKey,
        'Content-Type: application/json',
    );

    $notification = array(
        'title' => $title,
        'body' => $body,
        'image' => $iconUrl, // Menggunakan image untuk menyertakan URL gambar
    );

    $data = array(
        'to' => $deviceToken,
        'notification' => $notification,
    );

    $payload = json_encode($data);

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);

    $result = curl_exec($ch);
    curl_close($ch);

    return $result;
}

$iconUrl = 'http://192.168.99.252/bago.jpg'; // Ganti dengan URL gambar dari asset

$sql_pppoe = $koneksi->query("SELECT * FROM ppoe WHERE user='$user'");
$data_pppoe = $sql_pppoe->fetch_assoc();
if ($data_pppoe['cabang'] === 'indra') {
    $data_pppoe['cabang'] = 'bago';
}

// Ambil data teknisi
$sql_teknisi = $koneksi->query("SELECT * FROM teknisi WHERE cabang= '$data_pppoe[cabang]'");
$data_teknisi = $sql_teknisi->fetch_assoc();

// Ambil data device_tokens
$sql_device_token = $koneksi->query("SELECT * FROM device_tokens WHERE teknisi_id='$data_teknisi[id]'");
$data_device_token = $sql_device_token->fetch_assoc();
$now = date('Y-m-d H:i:s');
if ($sts == '1') {
    $title="Terhubung $data_pppoe[user]";
    $pesan =  "Terhubung $data_pppoe[user] pada $now";
} else {
    $title="Terputus $data_pppoe[user]";
    $pesan =  "Terputus $data_pppoe[user] pada $now";
}
// Simpan notifikasi ke tabel notifications
$sql_insert_notification = "INSERT INTO notifications (user_id, title, body, is_read, created_at, sts) VALUES ('$data_teknisi[id]', '$title', '$pesan', '0', NOW(), '1')";
if ($koneksi->query($sql_insert_notification) === TRUE) {
    echo "Notifikasi berhasil disimpan.";
} else {
    echo "Error: " . $sql_insert_notification . "<br>" . $koneksi->error;
}


 
// Kirim notifikasi
$response = sendNotification($data_device_token['device_token'], $title, $pesan, $iconUrl);

// Handle response
if ($response === false) {
    echo 'Gagal mengirim notifikasi ke ' . $data_device_token['device_token'] . '<br>';
} else {
    echo 'Notifikasi berhasil dikirim ke ' . $data_device_token['device_token'] . '<br>';
}

$koneksi->close();


?>
