-- phpMyAdmin SQL Dump
-- version 4.9.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Erstellungszeit: 06. Jan 2020 um 23:42
-- Server-Version: 10.4.11-MariaDB
-- PHP-Version: 7.4.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Datenbank: `fotos`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `attribute`
--

CREATE TABLE `attribute` (
  `ID_ATTRIBUT` int(10) UNSIGNED NOT NULL,
  `NAME` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `cluster`
--

CREATE TABLE `cluster` (
  `ID_CLUSTER` int(10) UNSIGNED NOT NULL,
  `CENTER_LAT` float NOT NULL,
  `CENTER_LON` float NOT NULL,
  `RADIUS` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `fotos`
--

CREATE TABLE `fotos` (
  `ID_FOTO` int(10) UNSIGNED NOT NULL,
  `GPS_LAT` float DEFAULT NULL,
  `GPS_LON` float DEFAULT NULL,
  `GPS_ALT` float DEFAULT NULL,
  `TS_CREATE` int(10) UNSIGNED NOT NULL,
  `ID_TIME_ACCURACY` tinyint(4) NOT NULL,
  `WIDTH` int(10) UNSIGNED DEFAULT NULL,
  `HEIGHT` int(10) UNSIGNED DEFAULT NULL,
  `ID_ORIENTATION` tinyint(4) DEFAULT NULL,
  `FILE_BASE` varchar(100) NOT NULL,
  `FILE_DIR` varchar(255) NOT NULL,
  `FILE_NAME` varchar(100) NOT NULL,
  `ID_CLUSTER` int(10) UNSIGNED DEFAULT NULL,
  `TS_IMPORT` int(10) UNSIGNED NOT NULL,
  `SHA256` char(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `foto_attribute`
--

CREATE TABLE `foto_attribute` (
  `ID_FOTO` int(10) UNSIGNED NOT NULL,
  `ID_ATTRIBUT` int(10) UNSIGNED NOT NULL,
  `WERT` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `orientation`
--

CREATE TABLE `orientation` (
  `ID_ORIENTATION` int(11) NOT NULL,
  `NAME` varchar(50) NOT NULL,
  `ROTATE` smallint(6) NOT NULL,
  `FLIP_HORIZONTAL` bit(1) NOT NULL,
  `FLIP_VERTICAL` bit(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `orientation`
--

INSERT INTO `orientation` (`ID_ORIENTATION`, `NAME`, `ROTATE`, `FLIP_HORIZONTAL`, `FLIP_VERTICAL`) VALUES
(1, 'Horizontal (normal)', 0, b'0', b'0'),
(2, 'Mirror horizontal', 0, b'1', b'0'),
(3, 'Rotate 180', 180, b'0', b'0'),
(4, 'Mirror vertical', 0, b'0', b'1'),
(5, 'Mirror horizontal and rotate 270 CW', 270, b'1', b'0'),
(6, 'Rotate 90 CW', 90, b'0', b'0'),
(7, 'Mirror horizontal and rotate 90 CW', 90, b'1', b'0'),
(8, 'Rotate 270 CW', 270, b'0', b'0');

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `time_accuracy`
--

CREATE TABLE `time_accuracy` (
  `ID_TIME_ACCURACY` int(11) NOT NULL,
  `NAME` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Daten für Tabelle `time_accuracy`
--

INSERT INTO `time_accuracy` (`ID_TIME_ACCURACY`, `NAME`) VALUES
(-1, 'Unknown'),
(1, 'GPS Time'),
(2, 'Creation Time from EXIF'),
(3, 'Date in gallery.cfg'),
(4, 'Time from folder name'),
(5, 'Last change of file');

--
-- Indizes der exportierten Tabellen
--

--
-- Indizes für die Tabelle `attribute`
--
ALTER TABLE `attribute`
  ADD PRIMARY KEY (`ID_ATTRIBUT`);

--
-- Indizes für die Tabelle `cluster`
--
ALTER TABLE `cluster`
  ADD PRIMARY KEY (`ID_CLUSTER`);

--
-- Indizes für die Tabelle `fotos`
--
ALTER TABLE `fotos`
  ADD PRIMARY KEY (`ID_FOTO`),
  ADD UNIQUE KEY `FOTOS_SHA256` (`SHA256`) USING BTREE;

--
-- Indizes für die Tabelle `foto_attribute`
--
ALTER TABLE `foto_attribute`
  ADD PRIMARY KEY (`ID_FOTO`,`ID_ATTRIBUT`);

--
-- Indizes für die Tabelle `orientation`
--
ALTER TABLE `orientation`
  ADD PRIMARY KEY (`ID_ORIENTATION`);

--
-- Indizes für die Tabelle `time_accuracy`
--
ALTER TABLE `time_accuracy`
  ADD PRIMARY KEY (`ID_TIME_ACCURACY`);

--
-- AUTO_INCREMENT für exportierte Tabellen
--

--
-- AUTO_INCREMENT für Tabelle `fotos`
--
ALTER TABLE `fotos`
  MODIFY `ID_FOTO` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
