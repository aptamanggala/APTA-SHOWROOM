-- =====================================================
-- PBD UTS - DDL (MySQL / InnoDB / utf8mb4)
-- =====================================================
DROP DATABASE IF EXISTS db_pbd;
CREATE DATABASE db_pbd CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE db_pbd;

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
  PRIMARY KEY (idrole)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 3. user ----------
CREATE TABLE `user` (
  iduser   INT          NOT NULL AUTO_INCREMENT,
  username VARCHAR(45)  NOT NULL,
  password VARCHAR(100) NOT NULL,
  idrole   INT          NOT NULL,
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
  harga    INT         NOT NULL,
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
  subtotal_nilai  INT       NOT NULL DEFAULT 0,
  ppn             INT       NOT NULL DEFAULT 0,
  total_nilai     INT       NOT NULL DEFAULT 0,
  PRIMARY KEY (idpengadaan),
  CONSTRAINT fk_pengadaan_user   FOREIGN KEY (user_iduser)     REFERENCES `user` (iduser),
  CONSTRAINT fk_pengadaan_vendor FOREIGN KEY (vendor_idvendor) REFERENCES vendor (idvendor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 8. detail_pengadaan ----------
CREATE TABLE detail_pengadaan (
  iddetail_pengadaan BIGINT NOT NULL AUTO_INCREMENT,
  harga_satuan       INT    NOT NULL,
  jumlah             INT    NOT NULL,
  sub_total          INT    NOT NULL,
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
  status       CHAR(1)   NOT NULL,
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
  harga_satuan_terima  INT    NOT NULL,
  sub_total_terima     INT    NOT NULL,
  PRIMARY KEY (iddetail_penerimaan),
  CONSTRAINT fk_dpenerimaan_penerimaan FOREIGN KEY (idpenerimaan)    REFERENCES penerimaan (idpenerimaan),
  CONSTRAINT fk_dpenerimaan_barang     FOREIGN KEY (barang_idbarang) REFERENCES barang (idbarang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 11. penjualan ----------
CREATE TABLE penjualan (
  idpenjualan        INT       NOT NULL AUTO_INCREMENT,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal_nilai     INT       NOT NULL DEFAULT 0,
  ppn                INT       NOT NULL DEFAULT 0,
  total_nilai        INT       NOT NULL DEFAULT 0,
  iduser             INT       NOT NULL,
  idmargin_penjualan INT       NOT NULL,
  PRIMARY KEY (idpenjualan),
  CONSTRAINT fk_penjualan_user   FOREIGN KEY (iduser)             REFERENCES `user` (iduser),
  CONSTRAINT fk_penjualan_margin FOREIGN KEY (idmargin_penjualan) REFERENCES margin_penjualan (idmargin_penjualan)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------- 12. detail_penjualan ----------
CREATE TABLE detail_penjualan (
  iddetail_penjualan    BIGINT NOT NULL AUTO_INCREMENT,
  harga_satuan          INT    NOT NULL,
  jumlah                INT    NOT NULL,
  subtotal              INT    NOT NULL,
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
  idtransaksi     INT       NOT NULL,
  idbarang        INT       NOT NULL,
  PRIMARY KEY (idkartu_stok),
  CONSTRAINT fk_kartustok_barang FOREIGN KEY (idbarang) REFERENCES barang (idbarang)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
