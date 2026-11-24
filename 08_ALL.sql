-- 08_ALL.sql — gabungan 00 sampai 06 (struktur, data awal, function, view, trigger, SP, stok awal).
-- Cukup jalankan file ini sekali untuk membuat seluruh database dari nol. 07_TES_DEMO.sql dijalankan terpisah.

DROP DATABASE IF EXISTS db_pbd_demo;
CREATE DATABASE db_pbd_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE db_pbd_demo;

-- Semua nilai uang disimpan dalam RUPIAH PENUH (BIGINT), bukan juta, supaya PPN dan harga jual tidak terbulat.

-- ---------- 1. satuan ----------
CREATE TABLE satuan (
  idsatuan    INT         NOT NULL AUTO_INCREMENT,
  nama_satuan VARCHAR(45) NOT NULL,
  status      TINYINT     NOT NULL DEFAULT 1,
  PRIMARY KEY (idsatuan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 2. role ----------
CREATE TABLE role (
  idrole    INT          NOT NULL AUTO_INCREMENT,
  nama_role VARCHAR(100) NOT NULL,
  status    TINYINT      NOT NULL DEFAULT 1,
  PRIMARY KEY (idrole)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 2b. role_menu (hak akses: menu apa saja yang boleh dibuka tiap role) ----------
CREATE TABLE role_menu (
  idrole INT         NOT NULL,
  menu   VARCHAR(30) NOT NULL,
  PRIMARY KEY (idrole, menu),
  CONSTRAINT fk_rolemenu_role FOREIGN KEY (idrole) REFERENCES role (idrole) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 3. user ----------
CREATE TABLE `user` (
  iduser   INT          NOT NULL AUTO_INCREMENT,
  username VARCHAR(45)  NOT NULL,
  password VARCHAR(100) NOT NULL,
  idrole   INT          NOT NULL,
  status   TINYINT      NOT NULL DEFAULT 1,
  PRIMARY KEY (iduser),
  CONSTRAINT fk_user_role FOREIGN KEY (idrole) REFERENCES role (idrole)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 4. vendor ----------
CREATE TABLE vendor (
  idvendor     INT          NOT NULL AUTO_INCREMENT,
  nama_vendor  VARCHAR(100) NOT NULL,
  badan_hukum  CHAR(1)      NOT NULL,
  status       CHAR(1)      NOT NULL,
  PRIMARY KEY (idvendor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 5. barang ----------
CREATE TABLE barang (
  idbarang INT         NOT NULL AUTO_INCREMENT,
  jenis    CHAR(1)     NOT NULL,
  nama     VARCHAR(45) NOT NULL,
  idsatuan INT         NOT NULL,
  status   TINYINT     NOT NULL DEFAULT 1,
  harga    BIGINT      NOT NULL,   -- rupiah penuh
  PRIMARY KEY (idbarang),
  CONSTRAINT fk_barang_satuan FOREIGN KEY (idsatuan) REFERENCES satuan (idsatuan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 6. margin_penjualan ----------
CREATE TABLE margin_penjualan (
  idmargin_penjualan INT       NOT NULL AUTO_INCREMENT,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  persen             DOUBLE    NOT NULL,
  status             TINYINT   NOT NULL DEFAULT 0,
  iduser             INT       NOT NULL,
  updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (idmargin_penjualan),
  CONSTRAINT fk_margin_user FOREIGN KEY (iduser) REFERENCES `user` (iduser)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 7. pengadaan ----------
CREATE TABLE pengadaan (
  idpengadaan     BIGINT    NOT NULL AUTO_INCREMENT,
  `timestamp`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  user_iduser     INT       NOT NULL,
  status          CHAR(1)   NOT NULL,
  vendor_idvendor INT       NOT NULL,
  subtotal_nilai  BIGINT    NOT NULL DEFAULT 0,
  ppn             BIGINT    NOT NULL DEFAULT 0,
  total_nilai     BIGINT    NOT NULL DEFAULT 0,
  PRIMARY KEY (idpengadaan),
  CONSTRAINT fk_pengadaan_user   FOREIGN KEY (user_iduser)     REFERENCES `user` (iduser),
  CONSTRAINT fk_pengadaan_vendor FOREIGN KEY (vendor_idvendor) REFERENCES vendor (idvendor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 8. detail_pengadaan ----------
CREATE TABLE detail_pengadaan (
  iddetail_pengadaan BIGINT NOT NULL AUTO_INCREMENT,
  harga_satuan       BIGINT NOT NULL,
  jumlah             INT    NOT NULL,
  sub_total          BIGINT NOT NULL,
  idbarang           INT    NOT NULL,
  idpengadaan        BIGINT NOT NULL,
  PRIMARY KEY (iddetail_pengadaan),
  CONSTRAINT fk_dpengadaan_barang    FOREIGN KEY (idbarang)    REFERENCES barang (idbarang),
  CONSTRAINT fk_dpengadaan_pengadaan FOREIGN KEY (idpengadaan) REFERENCES pengadaan (idpengadaan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 9. penerimaan ----------
CREATE TABLE penerimaan (
  idpenerimaan BIGINT    NOT NULL AUTO_INCREMENT,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status       CHAR(1)   NOT NULL,     -- P = sebagian (pengadaan masih Proses), S = lengkap (pengadaan Selesai)
  idpengadaan  BIGINT    NOT NULL,
  iduser       INT       NOT NULL,
  PRIMARY KEY (idpenerimaan),
  CONSTRAINT fk_penerimaan_pengadaan FOREIGN KEY (idpengadaan) REFERENCES pengadaan (idpengadaan),
  CONSTRAINT fk_penerimaan_user      FOREIGN KEY (iduser)      REFERENCES `user` (iduser)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 10. detail_penerimaan ----------
CREATE TABLE detail_penerimaan (
  iddetail_penerimaan  BIGINT NOT NULL AUTO_INCREMENT,
  idpenerimaan         BIGINT NOT NULL,
  barang_idbarang      INT    NOT NULL,
  jumlah_terima        INT    NOT NULL,
  harga_satuan_terima  BIGINT NOT NULL,
  sub_total_terima     BIGINT NOT NULL,
  PRIMARY KEY (iddetail_penerimaan),
  CONSTRAINT fk_dpenerimaan_penerimaan FOREIGN KEY (idpenerimaan)    REFERENCES penerimaan (idpenerimaan),
  CONSTRAINT fk_dpenerimaan_barang     FOREIGN KEY (barang_idbarang) REFERENCES barang (idbarang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 11. penjualan ----------
CREATE TABLE penjualan (
  idpenjualan        INT       NOT NULL AUTO_INCREMENT,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal_nilai     BIGINT    NOT NULL DEFAULT 0,
  ppn                BIGINT    NOT NULL DEFAULT 0,
  total_nilai        BIGINT    NOT NULL DEFAULT 0,
  iduser             INT       NOT NULL,
  idmargin_penjualan INT       NOT NULL,
  PRIMARY KEY (idpenjualan),
  CONSTRAINT fk_penjualan_user   FOREIGN KEY (iduser)             REFERENCES `user` (iduser),
  CONSTRAINT fk_penjualan_margin FOREIGN KEY (idmargin_penjualan) REFERENCES margin_penjualan (idmargin_penjualan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 12. detail_penjualan ----------
CREATE TABLE detail_penjualan (
  iddetail_penjualan    BIGINT NOT NULL AUTO_INCREMENT,
  harga_satuan          BIGINT NOT NULL,
  jumlah                INT    NOT NULL,
  subtotal              BIGINT NOT NULL,
  penjualan_idpenjualan INT    NOT NULL,
  idbarang              INT    NOT NULL,
  PRIMARY KEY (iddetail_penjualan),
  CONSTRAINT fk_dpenjualan_penjualan FOREIGN KEY (penjualan_idpenjualan) REFERENCES penjualan (idpenjualan),
  CONSTRAINT fk_dpenjualan_barang    FOREIGN KEY (idbarang)              REFERENCES barang (idbarang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 13. retur ----------
CREATE TABLE retur (
  idretur      BIGINT    NOT NULL AUTO_INCREMENT,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  idpenerimaan BIGINT    NOT NULL,
  iduser       INT       NOT NULL,
  PRIMARY KEY (idretur),
  CONSTRAINT fk_retur_penerimaan FOREIGN KEY (idpenerimaan) REFERENCES penerimaan (idpenerimaan),
  CONSTRAINT fk_retur_user       FOREIGN KEY (iduser)       REFERENCES `user` (iduser)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 14. detail_retur ----------
CREATE TABLE detail_retur (
  iddetail_retur      INT          NOT NULL AUTO_INCREMENT,
  jumlah              INT          NOT NULL,
  alasan              VARCHAR(200) NOT NULL,
  idretur             BIGINT       NOT NULL,
  iddetail_penerimaan BIGINT       NOT NULL,
  PRIMARY KEY (iddetail_retur),
  CONSTRAINT fk_dretur_retur             FOREIGN KEY (idretur)             REFERENCES retur (idretur),
  CONSTRAINT fk_dretur_detail_penerimaan FOREIGN KEY (iddetail_penerimaan) REFERENCES detail_penerimaan (iddetail_penerimaan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 15. kartu_stok ----------
CREATE TABLE kartu_stok (
  idkartu_stok    BIGINT    NOT NULL AUTO_INCREMENT,
  jenis_transaksi CHAR(1)   NOT NULL,
  masuk           INT       NOT NULL DEFAULT 0,
  keluar          INT       NOT NULL DEFAULT 0,
  stock           INT       NOT NULL DEFAULT 0,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  idtransaksi     BIGINT    NOT NULL,
  idbarang        INT       NOT NULL,
  PRIMARY KEY (idkartu_stok),
  CONSTRAINT fk_kartustok_barang FOREIGN KEY (idbarang) REFERENCES barang (idbarang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
USE db_pbd_demo;

-- Data awal yang bersih. Contoh INSERT / UPDATE / DELETE per tabel master ada di 07_TES_DEMO.sql.
-- Semua nilai uang dalam RUPIAH PENUH.

-- ---------- 1. satuan ----------
INSERT INTO satuan (nama_satuan, status) VALUES
 ('Unit', 1), ('Set Lengkap', 1), ('Paket', 1);

-- ---------- 2. role ----------
INSERT INTO role (nama_role) VALUES ('Direktur Utama'), ('Manajer Gudang'), ('Sales Executive');

-- ---------- 2b. role_menu (hak akses) ----------
-- Direktur Utama = semua menu
-- Manajer Gudang = barang, pengadaan, penerimaan, retur, stok
-- Sales Executive = penjualan, stok
INSERT INTO role_menu (idrole, menu) VALUES
 (1, 'satuan'), (1, 'role'), (1, 'user'), (1, 'vendor'), (1, 'barang'), (1, 'margin'),
 (1, 'pengadaan'), (1, 'penerimaan'), (1, 'retur'), (1, 'penjualan'), (1, 'stok'),
 (2, 'barang'), (2, 'pengadaan'), (2, 'penerimaan'), (2, 'retur'), (2, 'stok'),
 (3, 'penjualan'), (3, 'stok');

-- ---------- 3. user ----------
-- Password semua user demo = Aptasalim11 (disimpan sebagai hash bcrypt, dipakai di halaman login)
INSERT INTO `user` (username, password, idrole) VALUES
 ('apta_dirut',          '$2y$10$ZMiLmiN.w8jeW34I8Nj.lepgG9FwW84RV4U3ovvn38eN3p7bA4dnm', 1),
 ('gudang_apta',         '$2y$10$ZMiLmiN.w8jeW34I8Nj.lepgG9FwW84RV4U3ovvn38eN3p7bA4dnm', 2),
 ('sales_apta_prestige', '$2y$10$ZMiLmiN.w8jeW34I8Nj.lepgG9FwW84RV4U3ovvn38eN3p7bA4dnm', 3);

-- ---------- 4. vendor ----------
-- badan_hukum: P = PT, C = CV, U = UD/Perorangan | status: A = Aktif, N = Nonaktif
INSERT INTO vendor (nama_vendor, badan_hukum, status) VALUES
 ('PT Eropa Prima Motor', 'P', 'A'),
 ('CV Supercar Mandiri',  'C', 'A'),
 ('UD Garasi Klasik',     'U', 'N');

-- ---------- 5. barang ----------
-- jenis: B = Baru, S = Bekas | idsatuan 1 = Unit | harga dalam rupiah
INSERT INTO barang (jenis, nama, idsatuan, status, harga) VALUES
 ('S', 'Lamborghini Aventador', 1, 1, 15000000000),
 ('B', 'Porsche 911 Carrera',   1, 1,  5200000000),
 ('B', 'Ferrari 296 GTB',       1, 1, 12000000000);

-- ---------- 6. margin_penjualan ----------
-- 5 margin (10-50%), hanya 1 yang aktif (status = 1): margin 30%.
-- Hanya satu margin yang aktif; tombol "Aktifkan" di aplikasi menonaktifkan semua margin lalu mengaktifkan satu.
INSERT INTO margin_penjualan (persen, status, iduser) VALUES
 (10, 0, 1), (20, 0, 1), (30, 1, 1), (40, 0, 1), (50, 0, 1);
USE db_pbd_demo;

DELIMITER $$

-- =====================================================
-- FUNCTION (1): fn_harga_jual
-- Harga jual = harga barang + margin aktif (rupiah penuh, dibulatkan ke rupiah).
-- ORDER BY ... DESC = pengaman kalau (karena kelalaian) ada lebih dari satu margin aktif.
-- =====================================================
DROP FUNCTION IF EXISTS fn_harga_jual$$
CREATE FUNCTION fn_harga_jual(p_idbarang INT)
RETURNS BIGINT
READS SQL DATA
BEGIN
  DECLARE v_harga  BIGINT;
  DECLARE v_persen DOUBLE;

  SELECT harga INTO v_harga
  FROM barang
  WHERE idbarang = p_idbarang;

  IF v_harga IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(
           (SELECT persen
            FROM margin_penjualan
            WHERE status = 1
            ORDER BY idmargin_penjualan DESC
            LIMIT 1),
           0)
  INTO v_persen;

  RETURN ROUND(v_harga * (100 + v_persen) / 100);
END$$

-- =====================================================
-- FUNCTION (2): fn_hitung_ppn
-- Satu-satunya tempat tarif PPN (11%) didefinisikan. Dipakai oleh
-- sp_buat_pengadaan dan sp_buat_penjualan.
-- =====================================================
DROP FUNCTION IF EXISTS fn_hitung_ppn$$
CREATE FUNCTION fn_hitung_ppn(p_subtotal BIGINT)
RETURNS BIGINT
DETERMINISTIC
NO SQL
BEGIN
  RETURN ROUND(p_subtotal * 11 / 100);
END$$

DELIMITER ;
USE db_pbd_demo;



-- v_satuan
CREATE OR REPLACE VIEW v_satuan AS
SELECT
  s.idsatuan,
  s.nama_satuan,
  CASE s.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status
FROM satuan s;
 

--  v_role 
CREATE OR REPLACE VIEW v_role AS
SELECT
  r.idrole,
  r.nama_role,
  CASE r.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status,
  (SELECT COUNT(*) FROM role_menu rm WHERE rm.idrole = r.idrole) AS jumlah_menu
FROM role r;



--  v_user
CREATE OR REPLACE VIEW v_user AS
SELECT
  u.iduser,
  u.username,
  u.idrole,
  r.nama_role,
  CASE u.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status
FROM `user` u
JOIN role r ON r.idrole = u.idrole;
 

-- v_vendor 
CREATE OR REPLACE VIEW v_vendor AS
SELECT
  v.idvendor,
  v.nama_vendor,
  CASE v.badan_hukum
    WHEN 'P' THEN 'PT'
    WHEN 'C' THEN 'CV'
    WHEN 'U' THEN 'UD/Perorangan'
    ELSE v.badan_hukum
  END AS badan_hukum,
  CASE v.status
    WHEN 'A' THEN 'Aktif'
    WHEN 'N' THEN 'Nonaktif'
    ELSE v.status
  END AS status
FROM vendor v;
 
 
-- v_barang 
CREATE OR REPLACE VIEW v_barang AS
SELECT
  b.idbarang,
  CASE b.jenis
    WHEN 'B' THEN 'Baru'
    WHEN 'S' THEN 'Bekas'
    ELSE b.jenis
  END AS jenis,
  b.nama,
  b.idsatuan,
  s.nama_satuan,
  CASE b.status
    WHEN 1 THEN 'Aktif'
    ELSE 'Nonaktif'
  END AS status,
  b.harga
FROM barang b
JOIN satuan s ON s.idsatuan = b.idsatuan;
 
 
--  v_margin_penjualan 
CREATE OR REPLACE VIEW v_margin_penjualan AS
SELECT
  m.idmargin_penjualan,
  m.persen,
  m.status,
  m.iduser,
  u.username,
  m.created_at,
  m.updated_at
FROM margin_penjualan m
JOIN `user` u ON u.iduser = m.iduser;
 
 
 
 
 
 
 
 
 
 
 
 
 
 


-- View tabel transaksi (bukan 6 view utama)


-- v_pengadaan
CREATE OR REPLACE VIEW v_pengadaan AS
SELECT
  p.idpengadaan,
  p.`timestamp` AS waktu,
  v.nama_vendor,
  u.username,
  p.status,
  CASE p.status
    WHEN 'P' THEN 'Proses'
    WHEN 'S' THEN 'Selesai'
    ELSE p.status
  END AS nama_status,
  p.subtotal_nilai,
  p.ppn,
  p.total_nilai,
  CAST(COALESCE(d.pesan, 0) AS SIGNED)  AS jumlah_pesan,
  CAST(COALESCE(t.terima, 0) AS SIGNED) AS jumlah_terima,
  CASE WHEN COALESCE(d.pesan, 0) = 0 THEN 0
       ELSE CAST(ROUND(COALESCE(t.terima, 0) * 100 / d.pesan) AS SIGNED)
  END AS persen_terima
FROM pengadaan p
JOIN vendor v ON v.idvendor = p.vendor_idvendor
JOIN `user` u ON u.iduser   = p.user_iduser
LEFT JOIN (SELECT idpengadaan, SUM(jumlah) AS pesan
           FROM detail_pengadaan
           GROUP BY idpengadaan) d ON d.idpengadaan = p.idpengadaan
LEFT JOIN (SELECT pn.idpengadaan, SUM(dt.jumlah_terima) AS terima
           FROM detail_penerimaan dt
           JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
           GROUP BY pn.idpengadaan) t ON t.idpengadaan = p.idpengadaan;

-- v_detail_pengadaan (dilengkapi jumlah yang sudah diterima dan sisanya)
CREATE OR REPLACE VIEW v_detail_pengadaan AS
SELECT
  dp.iddetail_pengadaan,
  dp.idpengadaan,
  dp.idbarang,
  b.nama,
  s.nama_satuan,
  dp.harga_satuan,
  dp.jumlah,
  dp.sub_total,
  COALESCE((SELECT SUM(dt.jumlah_terima)
            FROM detail_penerimaan dt
            JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
            WHERE pn.idpengadaan = dp.idpengadaan
              AND dt.barang_idbarang = dp.idbarang), 0) AS diterima,
  dp.jumlah - COALESCE((SELECT SUM(dt.jumlah_terima)
                        FROM detail_penerimaan dt
                        JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
                        WHERE pn.idpengadaan = dp.idpengadaan
                          AND dt.barang_idbarang = dp.idbarang), 0) AS sisa
FROM detail_pengadaan dp
JOIN barang b ON b.idbarang = dp.idbarang
JOIN satuan s ON s.idsatuan = b.idsatuan;

-- v_sisa_pengadaan: per pengadaan per barang -> dipesan, diterima, sisa (dasar form penerimaan & SP)
CREATE OR REPLACE VIEW v_sisa_pengadaan AS
SELECT
  dp.idpengadaan,
  dp.idbarang,
  b.nama,
  s.nama_satuan,
  dp.harga_satuan,
  CAST(SUM(dp.jumlah) AS SIGNED) AS dipesan,
  CAST(COALESCE(t.diterima, 0) AS SIGNED) AS diterima,
  CAST(SUM(dp.jumlah) - COALESCE(t.diterima, 0) AS SIGNED) AS sisa
FROM detail_pengadaan dp
JOIN barang b ON b.idbarang = dp.idbarang
JOIN satuan s ON s.idsatuan = b.idsatuan
LEFT JOIN (SELECT pn.idpengadaan,
                  dt.barang_idbarang AS idbarang,
                  SUM(dt.jumlah_terima) AS diterima
           FROM detail_penerimaan dt
           JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
           GROUP BY pn.idpengadaan, dt.barang_idbarang) t
       ON t.idpengadaan = dp.idpengadaan AND t.idbarang = dp.idbarang
GROUP BY dp.idpengadaan, dp.idbarang, b.nama, s.nama_satuan, dp.harga_satuan, t.diterima;

-- v_penerimaan: satu baris per pengadaan + progres penerimaan (Proses / Selesai)
CREATE OR REPLACE VIEW v_penerimaan AS
SELECT
  vp.idpengadaan,
  vp.waktu,
  vp.nama_vendor,
  vp.username,
  vp.status,
  vp.nama_status,
  vp.jumlah_pesan,
  vp.jumlah_terima,
  vp.persen_terima,
  (SELECT COUNT(*) FROM penerimaan pn
   WHERE pn.idpengadaan = vp.idpengadaan) AS kali_terima,
  (SELECT MAX(pn.created_at) FROM penerimaan pn
   WHERE pn.idpengadaan = vp.idpengadaan) AS terakhir_terima
FROM v_pengadaan vp;

-- v_riwayat_penerimaan: satu baris per kali terima (header penerimaan)
-- status P = Sebagian (pengadaan belum lengkap), S = Lengkap. total_retur / sisa_retur untuk modul retur.
CREATE OR REPLACE VIEW v_riwayat_penerimaan AS
SELECT
  pn.idpenerimaan,
  pn.created_at,
  pn.idpengadaan,
  v.nama_vendor,
  u.username,
  pn.status,
  CASE pn.status
    WHEN 'P' THEN 'Sebagian'
    WHEN 'S' THEN 'Lengkap'
    ELSE pn.status
  END AS nama_status,
  CAST(COALESCE((SELECT SUM(dt.jumlah_terima)
                 FROM detail_penerimaan dt
                 WHERE dt.idpenerimaan = pn.idpenerimaan), 0) AS SIGNED) AS total_jumlah,
  CAST(COALESCE((SELECT SUM(dt.sub_total_terima)
                 FROM detail_penerimaan dt
                 WHERE dt.idpenerimaan = pn.idpenerimaan), 0) AS SIGNED) AS total_nilai,
  CAST(COALESCE((SELECT SUM(dr.jumlah)
                 FROM detail_retur dr
                 JOIN detail_penerimaan dt ON dt.iddetail_penerimaan = dr.iddetail_penerimaan
                 WHERE dt.idpenerimaan = pn.idpenerimaan), 0) AS SIGNED) AS total_retur,
  CAST(COALESCE((SELECT SUM(dt.jumlah_terima)
                 FROM detail_penerimaan dt
                 WHERE dt.idpenerimaan = pn.idpenerimaan), 0)
     - COALESCE((SELECT SUM(dr.jumlah)
                 FROM detail_retur dr
                 JOIN detail_penerimaan dt ON dt.iddetail_penerimaan = dr.iddetail_penerimaan
                 WHERE dt.idpenerimaan = pn.idpenerimaan), 0) AS SIGNED) AS sisa_retur
FROM penerimaan pn
JOIN pengadaan pg ON pg.idpengadaan = pn.idpengadaan
JOIN vendor v     ON v.idvendor     = pg.vendor_idvendor
JOIN `user` u     ON u.iduser       = pn.iduser;

-- v_detail_penerimaan
CREATE OR REPLACE VIEW v_detail_penerimaan AS
SELECT
  dt.iddetail_penerimaan,
  dt.idpenerimaan,
  dt.barang_idbarang AS idbarang,
  b.nama,
  s.nama_satuan,
  dt.harga_satuan_terima,
  dt.jumlah_terima,
  dt.sub_total_terima
FROM detail_penerimaan dt
JOIN barang b ON b.idbarang = dt.barang_idbarang
JOIN satuan s ON s.idsatuan = b.idsatuan;

-- v_penjualan
CREATE OR REPLACE VIEW v_penjualan AS
SELECT
  j.idpenjualan,
  j.created_at,
  u.username,
  m.persen AS margin_persen,
  j.subtotal_nilai,
  j.ppn,
  j.total_nilai
FROM penjualan j
JOIN `user` u            ON u.iduser = j.iduser
JOIN margin_penjualan m  ON m.idmargin_penjualan = j.idmargin_penjualan;

-- v_detail_penjualan
CREATE OR REPLACE VIEW v_detail_penjualan AS
SELECT
  d.iddetail_penjualan,
  d.penjualan_idpenjualan AS idpenjualan,
  d.idbarang,
  b.nama,
  s.nama_satuan,
  d.harga_satuan,
  d.jumlah,
  d.subtotal
FROM detail_penjualan d
JOIN barang b ON b.idbarang = d.idbarang
JOIN satuan s ON s.idsatuan = b.idsatuan;

-- v_stok: barang aktif + harga jual (fn_harga_jual) + stok terakhir dari kartu_stok
CREATE OR REPLACE VIEW v_stok AS
SELECT
  b.idbarang,
  b.nama,
  s.nama_satuan,
  b.harga,
  fn_harga_jual(b.idbarang) AS harga_jual,
  COALESCE((SELECT k.stock
            FROM kartu_stok k
            WHERE k.idbarang = b.idbarang
            ORDER BY k.idkartu_stok DESC
            LIMIT 1), 0) AS stok
FROM barang b
JOIN satuan s ON s.idsatuan = b.idsatuan
WHERE b.status = 1;

-- v_kartu_stok: kode P = Penerimaan, J = Penjualan, R = Retur (ke vendor)
CREATE OR REPLACE VIEW v_kartu_stok AS
SELECT
  k.idkartu_stok,
  k.idbarang,
  b.nama,
  k.created_at,
  CASE k.jenis_transaksi
    WHEN 'P' THEN IF(k.idtransaksi = 0, 'Stok awal', 'Penerimaan')
    WHEN 'J' THEN 'Penjualan'
    WHEN 'R' THEN 'Retur'
    ELSE k.jenis_transaksi
  END AS jenis_transaksi,
  k.idtransaksi,
  k.masuk,
  k.keluar,
  k.stock
FROM kartu_stok k
JOIN barang b ON b.idbarang = k.idbarang;


-- =====================================================
-- View master berstatus AKTIF (_aktif): sumber dropdown di form transaksi dan SP,
-- jadi data nonaktif tidak bisa dipilih.
-- =====================================================

-- v_vendor_aktif
CREATE OR REPLACE VIEW v_vendor_aktif AS
SELECT
  v.idvendor,
  v.nama_vendor,
  CASE v.badan_hukum
    WHEN 'P' THEN 'PT'
    WHEN 'C' THEN 'CV'
    WHEN 'U' THEN 'UD/Perorangan'
    ELSE v.badan_hukum
  END AS badan_hukum
FROM vendor v
WHERE v.status = 'A';

-- v_barang_aktif
CREATE OR REPLACE VIEW v_barang_aktif AS
SELECT
  b.idbarang,
  b.nama,
  CASE b.jenis
    WHEN 'B' THEN 'Baru'
    WHEN 'S' THEN 'Bekas'
    ELSE b.jenis
  END AS jenis,
  b.idsatuan,
  s.nama_satuan,
  b.harga
FROM barang b
JOIN satuan s ON s.idsatuan = b.idsatuan
WHERE b.status = 1;

-- v_margin_aktif: margin yang sedang dipakai untuk harga jual
CREATE OR REPLACE VIEW v_margin_aktif AS
SELECT m.idmargin_penjualan, m.persen, m.updated_at
FROM margin_penjualan m
WHERE m.status = 1;


-- =====================================================
-- View modul retur
-- =====================================================

-- v_sisa_retur: per baris penerimaan -> diterima, sudah diretur, sisa yang masih boleh diretur
CREATE OR REPLACE VIEW v_sisa_retur AS
SELECT
  dt.iddetail_penerimaan,
  dt.idpenerimaan,
  pn.idpengadaan,
  dt.barang_idbarang AS idbarang,
  b.nama,
  s.nama_satuan,
  dt.harga_satuan_terima,
  dt.jumlah_terima AS diterima,
  CAST(COALESCE((SELECT SUM(dr.jumlah)
                 FROM detail_retur dr
                 WHERE dr.iddetail_penerimaan = dt.iddetail_penerimaan), 0) AS SIGNED) AS diretur,
  CAST(dt.jumlah_terima - COALESCE((SELECT SUM(dr.jumlah)
                                    FROM detail_retur dr
                                    WHERE dr.iddetail_penerimaan = dt.iddetail_penerimaan), 0) AS SIGNED) AS sisa_retur
FROM detail_penerimaan dt
JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
JOIN barang b      ON b.idbarang      = dt.barang_idbarang
JOIN satuan s      ON s.idsatuan      = b.idsatuan;

-- v_retur: satu baris per retur (header)
CREATE OR REPLACE VIEW v_retur AS
SELECT
  r.idretur,
  r.created_at,
  r.idpenerimaan,
  pn.idpengadaan,
  v.nama_vendor,
  u.username,
  CAST(COALESCE((SELECT SUM(dr.jumlah)
                 FROM detail_retur dr
                 WHERE dr.idretur = r.idretur), 0) AS SIGNED) AS total_jumlah,
  CAST(COALESCE((SELECT SUM(dr.jumlah * dt.harga_satuan_terima)
                 FROM detail_retur dr
                 JOIN detail_penerimaan dt ON dt.iddetail_penerimaan = dr.iddetail_penerimaan
                 WHERE dr.idretur = r.idretur), 0) AS SIGNED) AS total_nilai
FROM retur r
JOIN penerimaan pn ON pn.idpenerimaan = r.idpenerimaan
JOIN pengadaan pg  ON pg.idpengadaan  = pn.idpengadaan
JOIN vendor v      ON v.idvendor      = pg.vendor_idvendor
JOIN `user` u      ON u.iduser        = r.iduser;

-- v_detail_retur
CREATE OR REPLACE VIEW v_detail_retur AS
SELECT
  dr.iddetail_retur,
  dr.idretur,
  dr.iddetail_penerimaan,
  dt.barang_idbarang AS idbarang,
  b.nama,
  s.nama_satuan,
  dt.harga_satuan_terima,
  dr.jumlah,
  CAST(dr.jumlah * dt.harga_satuan_terima AS SIGNED) AS nilai,
  dr.alasan
FROM detail_retur dr
JOIN detail_penerimaan dt ON dt.iddetail_penerimaan = dr.iddetail_penerimaan
JOIN barang b             ON b.idbarang             = dt.barang_idbarang
JOIN satuan s             ON s.idsatuan             = b.idsatuan;
USE db_pbd_demo;

-- Catatan konkurensi: setiap trigger yang mengubah stok mengunci baris barang (FOR UPDATE)
-- lalu membaca stok terakhir dengan FOR UPDATE juga, sehingga dua transaksi yang berjalan
-- bersamaan untuk barang yang sama dieksekusi bergantian (stok tidak bisa tembus / salah hitung).

-- =====================================================
-- TRIGGER (1): trg_detail_penjualan_ai
-- Setiap barang yang dijual otomatis keluar dari kartu stok (jenis 'J').
-- Menolak kalau stok tidak cukup.
-- =====================================================
DELIMITER $$

DROP TRIGGER IF EXISTS trg_detail_penjualan_ai$$
CREATE TRIGGER trg_detail_penjualan_ai
AFTER INSERT ON detail_penjualan
FOR EACH ROW
BEGIN
  DECLARE v_kunci INT;
  DECLARE v_stok  INT DEFAULT 0;

  SELECT idbarang INTO v_kunci
  FROM barang
  WHERE idbarang = NEW.idbarang
  FOR UPDATE;

  SELECT stock INTO v_stok
  FROM kartu_stok
  WHERE idbarang = NEW.idbarang
  ORDER BY idkartu_stok DESC
  LIMIT 1
  FOR UPDATE;

  IF v_stok < NEW.jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi';
  END IF;

  INSERT INTO kartu_stok (jenis_transaksi, masuk, keluar, stock, idtransaksi, idbarang)
  VALUES ('J', 0, NEW.jumlah, v_stok - NEW.jumlah, NEW.penjualan_idpenjualan, NEW.idbarang);
END$$

DELIMITER ;

-- =====================================================
-- TRIGGER (2): trg_detail_penerimaan_ai
-- Setiap barang yang diterima otomatis masuk ke kartu stok (jenis 'P').
-- Validasi ada di trigger juga (bukan hanya di SP), jadi INSERT langsung ke
-- detail_penerimaan pun tidak bisa menerima melebihi sisa pengadaan.
-- =====================================================
DELIMITER $$

DROP TRIGGER IF EXISTS trg_detail_penerimaan_ai$$
CREATE TRIGGER trg_detail_penerimaan_ai
AFTER INSERT ON detail_penerimaan
FOR EACH ROW
BEGIN
  DECLARE v_kunci     INT;
  DECLARE v_pengadaan BIGINT;
  DECLARE v_status    CHAR(1);
  DECLARE v_pesan     INT;
  DECLARE v_terima    INT DEFAULT 0;
  DECLARE v_stok      INT DEFAULT 0;

  IF NEW.jumlah_terima <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah diterima harus lebih dari 0';
  END IF;

  SELECT idbarang INTO v_kunci
  FROM barang
  WHERE idbarang = NEW.barang_idbarang
  FOR UPDATE;

  SELECT idpengadaan INTO v_pengadaan
  FROM penerimaan
  WHERE idpenerimaan = NEW.idpenerimaan
  FOR UPDATE;

  SELECT status INTO v_status
  FROM pengadaan
  WHERE idpengadaan = v_pengadaan
  FOR UPDATE;

  SELECT SUM(jumlah) INTO v_pesan
  FROM detail_pengadaan
  WHERE idpengadaan = v_pengadaan
    AND idbarang    = NEW.barang_idbarang
  FOR UPDATE;

  IF v_pesan IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang tidak ada di pengadaan ini';
  END IF;

  -- jumlah yang sudah diterima untuk barang ini (baris baru ini ikut terhitung).
  -- Tanpa FOR UPDATE karena detail_penerimaan adalah tabel pemicu; penguncian sudah di baris pengadaan di atas.
  SELECT COALESCE(SUM(dt.jumlah_terima), 0) INTO v_terima
  FROM detail_penerimaan dt
  JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
  WHERE pn.idpengadaan     = v_pengadaan
    AND dt.barang_idbarang = NEW.barang_idbarang;

  IF v_terima > v_pesan THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah diterima melebihi sisa pengadaan';
  END IF;

  SELECT stock INTO v_stok
  FROM kartu_stok
  WHERE idbarang = NEW.barang_idbarang
  ORDER BY idkartu_stok DESC
  LIMIT 1
  FOR UPDATE;

  INSERT INTO kartu_stok (jenis_transaksi, masuk, keluar, stock, idtransaksi, idbarang)
  VALUES ('P', NEW.jumlah_terima, 0, v_stok + NEW.jumlah_terima, NEW.idpenerimaan, NEW.barang_idbarang);
END$$

DELIMITER ;

-- =====================================================
-- TRIGGER (3): trg_detail_retur_ai
-- Barang yang diretur ke vendor otomatis keluar dari kartu stok (jenis 'R').
-- Menolak kalau jumlah retur melebihi jumlah yang diterima, atau stok tidak cukup
-- (misalnya barangnya sudah terjual).
-- =====================================================
DELIMITER $$

DROP TRIGGER IF EXISTS trg_detail_retur_ai$$
CREATE TRIGGER trg_detail_retur_ai
AFTER INSERT ON detail_retur
FOR EACH ROW
BEGIN
  DECLARE v_idbarang INT;
  DECLARE v_kunci    INT;
  DECLARE v_terima   INT;
  DECLARE v_retur    INT DEFAULT 0;
  DECLARE v_stok     INT DEFAULT 0;

  IF NEW.jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah retur harus lebih dari 0';
  END IF;

  -- kunci baris penerimaan ini (menyerialkan retur untuk baris yang sama) lalu barangnya
  SELECT barang_idbarang, jumlah_terima INTO v_idbarang, v_terima
  FROM detail_penerimaan
  WHERE iddetail_penerimaan = NEW.iddetail_penerimaan
  FOR UPDATE;

  IF v_idbarang IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Baris penerimaan tidak ditemukan';
  END IF;

  SELECT idbarang INTO v_kunci
  FROM barang
  WHERE idbarang = v_idbarang
  FOR UPDATE;

  -- total retur untuk baris penerimaan ini (baris baru ini ikut terhitung).
  -- Catatan: MySQL tidak mengizinkan FOR UPDATE pada tabel pemicu (detail_retur) di dalam trigger.
  SELECT COALESCE(SUM(jumlah), 0) INTO v_retur
  FROM detail_retur
  WHERE iddetail_penerimaan = NEW.iddetail_penerimaan;

  IF v_retur > v_terima THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah retur melebihi jumlah yang diterima';
  END IF;

  SELECT stock INTO v_stok
  FROM kartu_stok
  WHERE idbarang = v_idbarang
  ORDER BY idkartu_stok DESC
  LIMIT 1
  FOR UPDATE;

  IF v_stok < NEW.jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi untuk diretur';
  END IF;

  INSERT INTO kartu_stok (jenis_transaksi, masuk, keluar, stock, idtransaksi, idbarang)
  VALUES ('R', 0, NEW.jumlah, v_stok - NEW.jumlah, NEW.idretur, v_idbarang);
END$$

DELIMITER ;
USE db_pbd_demo;

-- Semua SP: transaksi (BEGIN/COMMIT) dipegang pemanggil (halaman PHP).
-- Semua validasi dilakukan SEBELUM ada data yang ditulis.
-- Pembacaan yang menentukan (stok, sisa pengadaan) memakai FOR UPDATE supaya aman
-- kalau dua transaksi berjalan bersamaan.

-- =====================================================
-- STORED PROCEDURE (1): sp_buat_pengadaan
-- Membuat pengadaan (pesanan ke vendor) satu barang per panggilan.
--   p_idpengadaan = 0 / NULL -> buat header pengadaan baru (status P = Proses)
--   p_idpengadaan = id lama  -> tambah barang ke pengadaan itu (harus masih Proses, vendor sama)
-- Isi SP: validasi -> header -> detail (harga dari barang; barang yang sama digabung)
--         -> hitung subtotal, PPN (fn_hitung_ppn), total.
-- =====================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_buat_pengadaan$$
CREATE PROCEDURE sp_buat_pengadaan(
  IN    p_iduser       INT,
  IN    p_idvendor     INT,
  IN    p_idbarang     INT,
  IN    p_jumlah       INT,
  INOUT p_idpengadaan  BIGINT
)
BEGIN
  DECLARE v_status  CHAR(1);
  DECLARE v_vendor  INT;
  DECLARE v_harga   BIGINT;
  DECLARE v_sub     BIGINT;
  DECLARE v_iddet   BIGINT;

  -- ---- validasi ----
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah harus lebih dari 0';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM `user` WHERE iduser = p_iduser AND status = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User tidak ditemukan atau nonaktif';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM v_vendor_aktif WHERE idvendor = p_idvendor) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vendor tidak ditemukan atau nonaktif';
  END IF;

  SELECT harga INTO v_harga
  FROM v_barang_aktif
  WHERE idbarang = p_idbarang;

  IF v_harga IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang tidak ditemukan atau nonaktif';
  END IF;

  -- ---- header pengadaan ----
  IF p_idpengadaan IS NULL OR p_idpengadaan = 0 THEN
    INSERT INTO pengadaan (user_iduser, status, vendor_idvendor)
    VALUES (p_iduser, 'P', p_idvendor);

    SET p_idpengadaan = LAST_INSERT_ID();
  ELSE
    SELECT status, vendor_idvendor INTO v_status, v_vendor
    FROM pengadaan
    WHERE idpengadaan = p_idpengadaan
    FOR UPDATE;

    IF v_status IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pengadaan tidak ditemukan';
    END IF;
    IF v_status <> 'P' THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pengadaan sudah selesai, tidak bisa ditambah barang lagi';
    END IF;
    IF v_vendor <> p_idvendor THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vendor tidak sama dengan vendor pengadaan ini';
    END IF;
  END IF;

  -- ---- detail pengadaan (barang yang sama digabung jadi satu baris) ----
  SELECT iddetail_pengadaan INTO v_iddet
  FROM detail_pengadaan
  WHERE idpengadaan = p_idpengadaan
    AND idbarang    = p_idbarang
  LIMIT 1
  FOR UPDATE;

  IF v_iddet IS NULL THEN
    INSERT INTO detail_pengadaan (harga_satuan, jumlah, sub_total, idbarang, idpengadaan)
    VALUES (v_harga, p_jumlah, v_harga * p_jumlah, p_idbarang, p_idpengadaan);
  ELSE
    UPDATE detail_pengadaan
    SET jumlah    = jumlah + p_jumlah,
        sub_total = harga_satuan * (jumlah + p_jumlah)
    WHERE iddetail_pengadaan = v_iddet;
  END IF;

  -- ---- total ----
  SELECT SUM(sub_total) INTO v_sub
  FROM detail_pengadaan
  WHERE idpengadaan = p_idpengadaan
  FOR UPDATE;

  UPDATE pengadaan
  SET subtotal_nilai = v_sub,
      ppn            = fn_hitung_ppn(v_sub),
      total_nilai    = v_sub + fn_hitung_ppn(v_sub)
  WHERE idpengadaan = p_idpengadaan;
END$$

DELIMITER ;

-- =====================================================
-- STORED PROCEDURE (2): sp_buat_penjualan
-- Membuat transaksi penjualan satu barang per panggilan.
--   p_idpenjualan = 0 / NULL -> buat header penjualan baru (margin aktif otomatis)
--   p_idpenjualan = id lama  -> tambah barang ke penjualan itu
-- Isi SP: validasi -> header -> detail (harga dari fn_harga_jual) -> hitung subtotal, PPN, total.
-- Insert detail_penjualan memicu trigger trg_detail_penjualan_ai (kartu stok keluar).
-- =====================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_buat_penjualan$$
CREATE PROCEDURE sp_buat_penjualan(
  IN    p_iduser       INT,
  IN    p_idbarang     INT,
  IN    p_jumlah       INT,
  INOUT p_idpenjualan  INT
)
BEGIN
  DECLARE v_idmargin INT;
  DECLARE v_kunci    INT;
  DECLARE v_stok     INT DEFAULT 0;
  DECLARE v_harga    BIGINT;
  DECLARE v_sub      BIGINT;

  -- ---- validasi ----
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah harus lebih dari 0';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM `user` WHERE iduser = p_iduser AND status = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User tidak ditemukan atau nonaktif';
  END IF;

  SELECT idbarang INTO v_kunci
  FROM barang
  WHERE idbarang = p_idbarang
    AND status   = 1
  FOR UPDATE;

  IF v_kunci IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang tidak ditemukan atau nonaktif';
  END IF;

  SELECT stock INTO v_stok
  FROM kartu_stok
  WHERE idbarang = p_idbarang
  ORDER BY idkartu_stok DESC
  LIMIT 1
  FOR UPDATE;

  IF v_stok < p_jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi';
  END IF;

  -- ---- header penjualan ----
  IF p_idpenjualan IS NULL OR p_idpenjualan = 0 THEN
    SELECT idmargin_penjualan INTO v_idmargin
    FROM v_margin_aktif
    ORDER BY idmargin_penjualan DESC
    LIMIT 1;

    IF v_idmargin IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tidak ada margin penjualan yang aktif';
    END IF;

    INSERT INTO penjualan (iduser, idmargin_penjualan)
    VALUES (p_iduser, v_idmargin);

    SET p_idpenjualan = LAST_INSERT_ID();
  ELSEIF NOT EXISTS (SELECT 1 FROM penjualan WHERE idpenjualan = p_idpenjualan) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Penjualan tidak ditemukan';
  END IF;

  -- ---- detail penjualan (memicu trigger -> kartu_stok) ----
  SET v_harga = fn_harga_jual(p_idbarang);

  INSERT INTO detail_penjualan (harga_satuan, jumlah, subtotal, penjualan_idpenjualan, idbarang)
  VALUES (v_harga, p_jumlah, v_harga * p_jumlah, p_idpenjualan, p_idbarang);

  -- ---- total ----
  SELECT SUM(subtotal) INTO v_sub
  FROM detail_penjualan
  WHERE penjualan_idpenjualan = p_idpenjualan;

  UPDATE penjualan
  SET subtotal_nilai = v_sub,
      ppn            = fn_hitung_ppn(v_sub),
      total_nilai    = v_sub + fn_hitung_ppn(v_sub)
  WHERE idpenjualan = p_idpenjualan;
END$$

DELIMITER ;

-- =====================================================
-- STORED PROCEDURE (3): sp_buat_penerimaan
-- Mencatat penerimaan barang dari satu pengadaan, satu barang per panggilan.
--   p_idpenerimaan = 0 / NULL -> buat header penerimaan baru
--   p_idpenerimaan = id lama  -> tambah barang ke penerimaan itu
-- Isi SP: validasi (pengadaan masih Proses, barang ada di pengadaan, jumlah <= sisa)
--         -> header -> detail (harga dari detail_pengadaan)
--         -> kalau semua barang sudah diterima penuh, status pengadaan menjadi 'S' (Selesai).
-- Status header penerimaan: P = Sebagian (pengadaan masih Proses), S = Lengkap (pengadaan Selesai).
-- Insert detail_penerimaan memicu trigger trg_detail_penerimaan_ai (validasi + kartu stok masuk).
-- =====================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_buat_penerimaan$$
CREATE PROCEDURE sp_buat_penerimaan(
  IN    p_iduser        INT,
  IN    p_idpengadaan   BIGINT,
  IN    p_idbarang      INT,
  IN    p_jumlah        INT,
  INOUT p_idpenerimaan  BIGINT
)
BEGIN
  DECLARE v_status      CHAR(1);
  DECLARE v_pesan       INT;
  DECLARE v_terima      INT DEFAULT 0;
  DECLARE v_harga       BIGINT;
  DECLARE v_tot_pesan   INT DEFAULT 0;
  DECLARE v_tot_terima  INT DEFAULT 0;
  DECLARE v_lengkap     TINYINT DEFAULT 0;

  -- ---- validasi ----
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah diterima harus lebih dari 0';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM `user` WHERE iduser = p_iduser AND status = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User tidak ditemukan atau nonaktif';
  END IF;

  SELECT status INTO v_status
  FROM pengadaan
  WHERE idpengadaan = p_idpengadaan
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pengadaan tidak ditemukan';
  END IF;

  IF v_status <> 'P' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pengadaan sudah selesai, tidak bisa menerima barang lagi';
  END IF;

  SELECT SUM(jumlah) INTO v_pesan
  FROM detail_pengadaan
  WHERE idpengadaan = p_idpengadaan
    AND idbarang    = p_idbarang
  FOR UPDATE;

  IF v_pesan IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang tidak ada di pengadaan ini';
  END IF;

  SELECT COALESCE(SUM(dt.jumlah_terima), 0) INTO v_terima
  FROM detail_penerimaan dt
  JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
  WHERE pn.idpengadaan     = p_idpengadaan
    AND dt.barang_idbarang = p_idbarang
  FOR UPDATE;

  IF p_jumlah > v_pesan - v_terima THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah diterima melebihi sisa pengadaan';
  END IF;

  -- ---- header penerimaan ----
  IF p_idpenerimaan IS NULL OR p_idpenerimaan = 0 THEN
    INSERT INTO penerimaan (status, idpengadaan, iduser)
    VALUES ('P', p_idpengadaan, p_iduser);

    SET p_idpenerimaan = LAST_INSERT_ID();
  ELSEIF NOT EXISTS (SELECT 1 FROM penerimaan
                     WHERE idpenerimaan = p_idpenerimaan
                       AND idpengadaan  = p_idpengadaan) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Penerimaan tidak ditemukan';
  END IF;

  -- ---- detail penerimaan (memicu trigger -> kartu_stok) ----
  SELECT harga_satuan INTO v_harga
  FROM detail_pengadaan
  WHERE idpengadaan = p_idpengadaan
    AND idbarang    = p_idbarang
  LIMIT 1;

  INSERT INTO detail_penerimaan (idpenerimaan, barang_idbarang, jumlah_terima, harga_satuan_terima, sub_total_terima)
  VALUES (p_idpenerimaan, p_idbarang, p_jumlah, v_harga, v_harga * p_jumlah);

  -- ---- status: Selesai kalau semua barang sudah diterima penuh ----
  SELECT COALESCE(SUM(jumlah), 0) INTO v_tot_pesan
  FROM detail_pengadaan
  WHERE idpengadaan = p_idpengadaan
  FOR UPDATE;

  SELECT COALESCE(SUM(dt.jumlah_terima), 0) INTO v_tot_terima
  FROM detail_penerimaan dt
  JOIN penerimaan pn ON pn.idpenerimaan = dt.idpenerimaan
  WHERE pn.idpengadaan = p_idpengadaan
  FOR UPDATE;

  IF v_tot_terima >= v_tot_pesan THEN
    SET v_lengkap = 1;
    UPDATE pengadaan SET status = 'S' WHERE idpengadaan = p_idpengadaan;
  END IF;

  UPDATE penerimaan
  SET status = IF(v_lengkap = 1, 'S', 'P')
  WHERE idpenerimaan = p_idpenerimaan;
END$$

DELIMITER ;

-- =====================================================
-- STORED PROCEDURE (4): sp_buat_retur
-- Mengembalikan barang yang sudah diterima ke vendor, satu baris penerimaan per panggilan.
--   p_idretur = 0 / NULL -> buat header retur baru
--   p_idretur = id lama  -> tambah baris ke retur itu (harus dari penerimaan yang sama)
-- Isi SP: validasi (jumlah <= sisa yang boleh diretur, stok cukup) -> header -> detail_retur.
-- Insert detail_retur memicu trigger trg_detail_retur_ai (kartu stok keluar, kode R).
-- =====================================================
DELIMITER $$

DROP PROCEDURE IF EXISTS sp_buat_retur$$
CREATE PROCEDURE sp_buat_retur(
  IN    p_iduser               INT,
  IN    p_iddetail_penerimaan  BIGINT,
  IN    p_jumlah               INT,
  IN    p_alasan               VARCHAR(200),
  INOUT p_idretur              BIGINT
)
BEGIN
  DECLARE v_idpenerimaan BIGINT;
  DECLARE v_idbarang     INT;
  DECLARE v_kunci        INT;
  DECLARE v_terima       INT;
  DECLARE v_retur        INT DEFAULT 0;
  DECLARE v_stok         INT DEFAULT 0;
  DECLARE v_pn_retur     BIGINT;

  -- ---- validasi ----
  IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah retur harus lebih dari 0';
  END IF;

  IF p_alasan IS NULL OR CHAR_LENGTH(TRIM(p_alasan)) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Alasan retur wajib diisi';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM `user` WHERE iduser = p_iduser AND status = 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User tidak ditemukan atau nonaktif';
  END IF;

  SELECT idpenerimaan, barang_idbarang, jumlah_terima
  INTO v_idpenerimaan, v_idbarang, v_terima
  FROM detail_penerimaan
  WHERE iddetail_penerimaan = p_iddetail_penerimaan
  FOR UPDATE;

  IF v_idpenerimaan IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Baris penerimaan tidak ditemukan';
  END IF;

  SELECT idbarang INTO v_kunci
  FROM barang
  WHERE idbarang = v_idbarang
  FOR UPDATE;

  SELECT COALESCE(SUM(jumlah), 0) INTO v_retur
  FROM detail_retur
  WHERE iddetail_penerimaan = p_iddetail_penerimaan
  FOR UPDATE;

  IF p_jumlah > v_terima - v_retur THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jumlah retur melebihi sisa yang bisa diretur';
  END IF;

  SELECT stock INTO v_stok
  FROM kartu_stok
  WHERE idbarang = v_idbarang
  ORDER BY idkartu_stok DESC
  LIMIT 1
  FOR UPDATE;

  IF v_stok < p_jumlah THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi untuk diretur';
  END IF;

  -- ---- header retur ----
  IF p_idretur IS NULL OR p_idretur = 0 THEN
    INSERT INTO retur (idpenerimaan, iduser)
    VALUES (v_idpenerimaan, p_iduser);

    SET p_idretur = LAST_INSERT_ID();
  ELSE
    SELECT idpenerimaan INTO v_pn_retur
    FROM retur
    WHERE idretur = p_idretur;

    IF v_pn_retur IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Retur tidak ditemukan';
    END IF;
    IF v_pn_retur <> v_idpenerimaan THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Baris ini berasal dari penerimaan lain';
    END IF;
  END IF;

  -- ---- detail retur (memicu trigger -> kartu_stok) ----
  INSERT INTO detail_retur (jumlah, alasan, idretur, iddetail_penerimaan)
  VALUES (p_jumlah, TRIM(p_alasan), p_idretur, p_iddetail_penerimaan);
END$$

DELIMITER ;
USE db_pbd_demo;

-- Stok awal (jenis 'P' = penerimaan, idtransaksi 0 = stok awal).

INSERT INTO kartu_stok (jenis_transaksi, masuk, keluar, stock, idtransaksi, idbarang)
SELECT 'P', x.jml, 0, x.jml, 0, x.idbarang
FROM (SELECT 1 AS idbarang, 3 AS jml
      UNION ALL SELECT 2, 5
      UNION ALL SELECT 3, 4) x
WHERE NOT EXISTS (SELECT 1 FROM kartu_stok);
