-- =====================================================
-- PBD UTS - DML untuk 6 data master (non-transaksi)
-- Tema: Apta Showroom (dealer mobil mewah)
-- Catatan: harga barang dalam JUTA RUPIAH (8500 = Rp 8,5 miliar)
-- =====================================================
USE db_pbd;

-- ---------- 1. satuan ----------
INSERT INTO satuan (nama_satuan, status) VALUES
 ('Unit', 1), ('Set', 1), ('Paket', 1), ('Buah', 0);
UPDATE satuan SET nama_satuan = 'Set Lengkap' WHERE idsatuan = 2;
DELETE FROM satuan WHERE idsatuan = 4;
SELECT * FROM satuan;

-- ---------- 2. role ----------
INSERT INTO role (nama_role) VALUES ('Owner'), ('Manajer Gudang'), ('Sales Executive');
UPDATE role SET nama_role = 'Direktur Utama' WHERE idrole = 1;
SELECT * FROM role;

-- ---------- 3. user ----------
INSERT INTO `user` (username, password, idrole) VALUES
 ('apta_dirut',  'Aptasalim11', 1),
 ('gudang_apta', 'Aptasalim11', 2),
 ('sales_apta',  'Aptasalim11', 3),
 ('tes_hapus',   'Aptasalim11', 3);
UPDATE `user` SET username = 'sales_apta_prestige' WHERE iduser = 3;
DELETE FROM `user` WHERE iduser = 4;
SELECT * FROM `user`;

-- ---------- 4. vendor ----------
-- badan_hukum: P = PT, C = CV, U = UD/Perorangan | status: A = Aktif, N = Nonaktif
INSERT INTO vendor (nama_vendor, badan_hukum, status) VALUES
 ('PT Eropa Prima Motor',     'P', 'A'),
 ('CV Supercar Mandiri',      'C', 'A'),
 ('UD Garasi Klasik',         'U', 'A'),
 ('PT Tes Hapus',             'P', 'N');
UPDATE vendor SET status = 'N' WHERE idvendor = 3;
DELETE FROM vendor WHERE idvendor = 4;
SELECT * FROM vendor;

-- ---------- 5. barang ----------
-- jenis: B = Baru, S = Bekas | idsatuan 1 = Unit | harga dalam juta rupiah
INSERT INTO barang (jenis, nama, idsatuan, status, harga) VALUES
 ('S', 'Lamborghini Aventador', 1, 1, 15000),
 ('B', 'Porsche 911 Carrera',   1, 1, 5000),
 ('B', 'Ferrari 296 GTB',       1, 1, 12000),
 ('B', 'Barang Tes Hapus',      1, 0, 1);
UPDATE barang SET harga = 5200 WHERE idbarang = 2;
DELETE FROM barang WHERE idbarang = 4;
SELECT * FROM barang;

-- ---------- 6. margin_penjualan ----------
-- 5 margin (10-50%), hanya 1 yang aktif (status = 1)
INSERT INTO margin_penjualan (persen, status, iduser) VALUES
 (10, 0, 1), (20, 1, 1), (30, 0, 1), (40, 0, 1), (50, 0, 1);
-- mengganti margin aktif: nonaktifkan semua, lalu aktifkan satu
UPDATE margin_penjualan SET status = 0 WHERE idmargin_penjualan > 0;
UPDATE margin_penjualan SET status = 1 WHERE idmargin_penjualan = 3;
SELECT * FROM margin_penjualan;
