<?php
// config/entities.php — definisi tabel master untuk CRUD generik.
// 'view'      : view yang dipakai untuk daftar (dari VIEW_APTA.sql)
// 'sp_tambah' : jika ada, tambah data lewat stored procedure (dari SP_APTA.sql)
// 'hanya_ubah': field hanya muncul di form ubah (nilainya diisi SP saat tambah)

$aktif    = ['1' => 'Aktif', '0' => 'Nonaktif'];
$fStatus  = ['status' => ['label' => 'Status', 'opsi' => ['Aktif' => 'Aktif', 'Nonaktif' => 'Nonaktif']]];

return [

    'satuan' => [
        'judul'     => 'Satuan',
        'tabel'     => 'satuan',
        'view'      => 'v_satuan',
        'pk'        => 'idsatuan',
        'kolom'     => [['idsatuan', 'ID'], ['nama_satuan', 'Nama satuan'], ['status', 'Status', 'badge']],
        'filter'    => $fStatus,
        'sp_tambah' => ['sp' => 'sp_tambah_satuan', 'param' => ['nama_satuan']],
        'field'     => [
            'nama_satuan' => ['label' => 'Nama satuan', 'tipe' => 'text', 'wajib' => true, 'panjang' => 45, 'unik' => true],
            'status'      => ['label' => 'Status', 'tipe' => 'select', 'wajib' => true, 'opsi' => $aktif, 'hanya_ubah' => true],
        ],
    ],

    'role' => [
        'judul'  => 'Role',
        'tabel'  => 'role',
        'view'   => 'v_role',
        'pk'     => 'idrole',
        'kolom'  => [['idrole', 'ID'], ['nama_role', 'Nama role']],
        'field'  => [
            'nama_role' => ['label' => 'Nama role', 'tipe' => 'text', 'wajib' => true, 'panjang' => 100, 'unik' => true],
        ],
    ],

    'user' => [
        'judul'  => 'User',
        'tabel'  => 'user',
        'view'   => 'v_user',
        'pk'     => 'iduser',
        'kolom'  => [['iduser', 'ID'], ['username', 'Username'], ['nama_role', 'Role']],
        'field'  => [
            'username' => ['label' => 'Username', 'tipe' => 'text', 'wajib' => true, 'panjang' => 45, 'unik' => true],
            'password' => ['label' => 'Password (saat ubah, kosongkan jika tidak diganti)', 'tipe' => 'password'],
            'idrole'   => ['label' => 'Role', 'tipe' => 'select', 'wajib' => true,
                           'opsi' => 'SELECT idrole, nama_role FROM role ORDER BY nama_role'],
        ],
    ],

    'vendor' => [
        'judul'     => 'Vendor',
        'tabel'     => 'vendor',
        'view'      => 'v_vendor',
        'pk'        => 'idvendor',
        'kolom'     => [['idvendor', 'ID'], ['nama_vendor', 'Nama vendor'], ['badan_hukum', 'Badan hukum'], ['status', 'Status', 'badge']],
        'filter'    => $fStatus,
        'sp_tambah' => ['sp' => 'sp_tambah_vendor', 'param' => ['nama_vendor', 'badan_hukum']],
        'field'     => [
            'nama_vendor' => ['label' => 'Nama vendor', 'tipe' => 'text', 'wajib' => true, 'panjang' => 100, 'unik' => true],
            'badan_hukum' => ['label' => 'Badan hukum', 'tipe' => 'select', 'wajib' => true,
                              'opsi' => ['P' => 'PT', 'C' => 'CV', 'U' => 'UD/Perorangan']],
            'status'      => ['label' => 'Status', 'tipe' => 'select', 'wajib' => true,
                              'opsi' => ['A' => 'Aktif', 'N' => 'Nonaktif'], 'hanya_ubah' => true],
        ],
    ],

    'barang' => [
        'judul'  => 'Barang',
        'tabel'  => 'barang',
        'view'   => 'v_barang',
        'pk'     => 'idbarang',
        'kolom'  => [['idbarang', 'ID'], ['nama', 'Nama'], ['jenis', 'Jenis'], ['nama_satuan', 'Satuan'],
                     ['harga', 'Harga', 'juta'], ['status', 'Status', 'badge']],
        'filter' => $fStatus + ['jenis' => ['label' => 'Jenis', 'opsi' => ['Baru' => 'Baru', 'Bekas' => 'Bekas']]],
        'field'  => [
            'nama'     => ['label' => 'Nama barang', 'tipe' => 'text', 'wajib' => true, 'panjang' => 45],
            'jenis'    => ['label' => 'Jenis', 'tipe' => 'select', 'wajib' => true, 'opsi' => ['B' => 'Baru', 'S' => 'Bekas']],
            'idsatuan' => ['label' => 'Satuan', 'tipe' => 'select', 'wajib' => true,
                           'opsi' => "SELECT idsatuan, CONCAT(nama_satuan, IF(status = 1, '', ' (nonaktif)')) FROM satuan ORDER BY nama_satuan"],
            'harga'    => ['label' => 'Harga (juta rupiah)', 'tipe' => 'number', 'wajib' => true, 'bulat' => true, 'min' => 0, 'maks' => 2147483647],
            'status'   => ['label' => 'Status', 'tipe' => 'select', 'wajib' => true, 'opsi' => $aktif],
        ],
    ],

    'margin' => [
        'judul'    => 'Margin',
        'tabel'    => 'margin_penjualan',
        'view'     => 'v_margin_penjualan',
        'pk'       => 'idmargin_penjualan',
        'aktifkan' => true, // tombol "Aktifkan" memanggil sp_ganti_margin_aktif
        'kolom'    => [['idmargin_penjualan', 'ID'], ['persen', 'Margin', 'persen'], ['username', 'Dibuat oleh'],
                       ['status', 'Status', 'status'], ['created_at', 'Dibuat'], ['updated_at', 'Diubah']],
        'filter'   => ['status' => ['label' => 'Status', 'opsi' => ['1' => 'Aktif', '0' => 'Nonaktif']]],
        'field'    => [
            'persen' => ['label' => 'Margin (%)', 'tipe' => 'number', 'wajib' => true, 'min' => 0, 'maks' => 100],
            'iduser' => ['label' => 'Dibuat oleh', 'tipe' => 'select', 'wajib' => true,
                         'opsi' => 'SELECT iduser, username FROM user ORDER BY username'],
        ],
    ],
];
