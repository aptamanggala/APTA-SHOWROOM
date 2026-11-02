<?php
// includes/header.php — butuh: $judul, $base, $kodeAktif (opsional)
$base      = $base ?? '../';
$kodeAktif = $kodeAktif ?? '';
?><!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h($judul) ?> — APTA</title>
    <link rel="stylesheet" href="<?= $base ?>assets/css/style.css">
</head>
<body>
<header class="atas">
    <a class="merek" href="<?= $base ?>index.php">APTA</a>
    <nav class="pills">
        <?php foreach (daftar_menu() as $k => $label): ?>
            <a class="pill<?= $k === $kodeAktif ? ' aktif' : '' ?>" href="<?= $base . $k ?>/index.php"><?= h($label) ?></a>
        <?php endforeach; ?>
    </nav>
</header>
<main>
    <h1><?= h($judul) ?></h1>
    <?php tampil_flash(); ?>
