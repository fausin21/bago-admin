<?php
// Koneksi ke database
$servername = "192.168.99.252"; // Ganti dengan nama server MySQL
$username = "fausin"; // Ganti dengan username MySQL
$password = "anggita"; // Ganti dengan password MySQL
$dbname = "app"; // Ganti dengan nama database

$conn = new mysqli($servername, $username, $password, $dbname);

// Periksa koneksi
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}

// Ambil pesan baru dari tabel 'wa'
$sql = "SELECT pesan FROM wa";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // Iterasi setiap pesan
    while($row = $result->fetch_assoc()) {
        $pesan = $row["pesan"];
        
        // Pisahkan pesan menjadi kata-kata
        $kata = explode(" ", $pesan);

        // Cocokkan kata-kata dengan 'username' di tabel 'usuarios'
        foreach ($kata as $k) {
            $sql_check = "SELECT username FROM usuarios WHERE username LIKE '%$k%'";
            $result_check = $conn->query($sql_check);
            
            if ($result_check->num_rows > 0) {
                // Jika ada kecocokan, tulis ke file teks
                $file = 'hasil.txt';
                $current = file_get_contents($file);
                $current .= "Kata '$k' cocok dengan username di tabel usuarios.\n";
                file_put_contents($file, $current);
            }
        }
    }
} else {
    echo "Tidak ada pesan baru.";
}
$conn->close();
?>