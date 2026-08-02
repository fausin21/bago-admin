<?php

//error_reporting(0);
require('routeros_api.class.php');
include 'kon.php';
include 'koneksi_radius.php';

// Ambil data username dari query awal
$query_usernames = mysqli_query($koneksi, "SELECT username FROM usuarios WHERE cabang IN ('bago', 'sentul')");

if (!$query_usernames) {
    die("Error fetching usernames: " . mysqli_error($koneksi));
}

while ($row = mysqli_fetch_assoc($query_usernames)) {
    $username = $row['username'];

    // Ambil detail user berdasarkan username
    $user_query = mysqli_query($koneksi, "SELECT * FROM usuarios WHERE username='$username'");
    if (!$user_query) {
        echo "Error getting user details: " . mysqli_error($koneksi) . "<br>";
        continue;
    }

    $user_data = mysqli_fetch_assoc($user_query);
    if (!$user_data) {
        echo "No data found for username: $username<br>";
        continue;
    }

    $nomer = str_replace(["0", "-", " ", "(", ")", "+"], ["62", "", "", "", "", ""], $user_data['no_hp']);
    $password = $user_data['password'];
    $cabang = $user_data['cabang'];

    date_default_timezone_set('Asia/Jakarta');
    $tanggal = date('d M Y H:i:s');
    $expired = date('d M Y H:i:s', strtotime('+1 month', strtotime($tanggal)));
    $session_time = date('Y-m-d\TH:i:sP', strtotime('+1 month', strtotime($tanggal)));

    // Ambil data teknisi berdasarkan cabang
    $ambil_cabang = mysqli_query($koneksi, "SELECT * FROM teknisi WHERE cabang='$cabang'");
    if (!$ambil_cabang) {
        echo "Error getting teknisi data: " . mysqli_error($koneksi) . "<br>";
        continue;
    }

    $teknisi_data = mysqli_fetch_assoc($ambil_cabang);
    if (!$teknisi_data) {
        echo "No teknisi found for cabang: $cabang<br>";
        continue;
    }

    $nomer_teknisi = $teknisi_data['nomer'];
    $nama_teknisi = $teknisi_data['nama'];

    // Cek dan update data di radcheck
    $result_radcheck = mysqli_query($konek, "SELECT * FROM radcheck WHERE username='$username'");
    if (!$result_radcheck) {
        echo "Error checking radcheck: " . mysqli_error($konek) . "<br>";
        continue;
    }

    if (mysqli_num_rows($result_radcheck) > 0) {
        $update_query = mysqli_query($konek, "UPDATE radcheck SET value='$expired' WHERE username='$username' AND attribute='expiration'");
        if (!$update_query) {
            echo "Error updating radcheck: " . mysqli_error($konek) . "<br>";
            continue;
        }
    } else {
        $insert_query = mysqli_query($konek, "INSERT INTO radcheck (username, attribute, op, value, nomer, no_teknisi, nama_teknisi) VALUES 
            ('$username', 'Cleartext-Password', ':=', '$password', '$nomer', '$nomer_teknisi', '$nama_teknisi'),
            ('$username', 'Port-Limit', ':=', '1', '$nomer', '$nomer_teknisi', '$nama_teknisi'),
            ('$username', 'Mikrotik-Wireless-Comment', ':=', 'Bago', '$nomer', '$nomer_teknisi', '$nama_teknisi'),
            ('$username', 'expiration', ':=', '$expired', '$nomer', '$nomer_teknisi', '$nama_teknisi'),
            ('$username', 'WISPr-Session-Terminate-Time', ':=', '$session_time', '$nomer', '$nomer_teknisi', '$nama_teknisi')");
        if (!$insert_query) {
            echo "Error inserting into radcheck: " . mysqli_error($konek) . "<br>";
            continue;
        }
    }

    // Cek dan update data di radreply
    $result_radreply = mysqli_query($konek, "SELECT * FROM radreply WHERE username='$username'");
    if (!$result_radreply) {
        echo "Error checking radreply: " . mysqli_error($konek) . "<br>";
        continue;
    }

    if (mysqli_num_rows($result_radreply) == 0) {
        $insert_reply = mysqli_query($konek, "INSERT INTO radreply (username, attribute, op, value) VALUES ('$username', 'Mikrotik-Rate-Limit', ':=', '2M/2M')");
        if (!$insert_reply) {
            echo "Error inserting into radreply: " . mysqli_error($konek) . "<br>";
            continue;
        }
    }

    echo "Successfully processed username: $username<br>";
}

?>