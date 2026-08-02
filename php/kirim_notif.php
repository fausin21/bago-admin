<?php

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

// Contoh penggunaan dengan menyertakan URL gambar dari asset
$deviceToken = 'cuH3LD8kSV-iI6nSP9c5rb:APA91bF5JB034Ypzwn8XUeZQA1XRZc9CdYppj1I20hPvn0493Zywg9_8FLvCm9beKyA1D6Nl3itqJuZXu0R8eCvbeAU73FggRQ-EOzu8dBqMFsEgRBobcv4mr8EB-P2Y1VqYz10ZGLif'; // Ganti dengan token perangkat yang valid
$title = 'Judul Notifikasi';
$body = 'Isi notifikasi';
$iconUrl = 'http://192.168.99.252/bago.jpg'; // Ganti dengan URL gambar dari asset

$response = sendNotification($deviceToken, $title, $body, $iconUrl);

// Handle response
if ($response === false) {
    echo 'Gagal mengirim notifikasi.';
} else {
    echo 'Notifikasi berhasil dikirim.';
}
?>

