<?php
include "kon.php";

// Menggunakan prepared statement untuk mencegah SQL injection
$userid = mysqli_real_escape_string($koneksi, $_GET['userid']);
 

// Menggunakan parameter binding untuk prepared statement
$query = "SELECT id, user_id, body, is_read, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC";
$stmt = mysqli_prepare($koneksi, $query);
mysqli_stmt_bind_param($stmt, 's', $userid);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

// Memasukkan hasil query ke dalam array
$notif = array();
while ($data = mysqli_fetch_assoc($result)) {
    $notif[] = array(
        'id' => $data['id'],
        'user_id' => $data['user_id'],
        'body' => $data['body'],
        'is_read' => $data['is_read'],
        'created_at' => $data['created_at'],
    );
}

// Menggunakan header untuk menetapkan tipe konten sebagai JSON
header('Content-Type: application/json');

// Menggunakan fungsi json_encode untuk mengonversi array ke JSON
echo json_encode($notif);

// Tutup statement dan koneksi
mysqli_stmt_close($stmt);
mysqli_close($koneksi);
?>
