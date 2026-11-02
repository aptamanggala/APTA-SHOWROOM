<?php
$host = "localhost";
$user = "root";
$pass = ""; // Kosongkan jika password root-mu tidak ada, atau isi jika pakai password
$db   = "db_pbd";

$conn = mysqli_connect($host, $user, $pass, $db);

if (!$conn) {
    die("Koneksi ke database gagal: " . mysqli_connect_error());
}
?>