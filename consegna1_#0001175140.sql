# 0) INIZIALIZZAZIONE DB
DROP DATABASE IF EXISTS FIERE_AZIENDALI;
CREATE DATABASE IF NOT EXISTS FIERE_AZIENDALI;
USE FIERE_AZIENDALI;

# CREAZIONE TABELLE DEL DB
CREATE TABLE FIERA (
	Nome VARCHAR(40) PRIMARY KEY,
    Ambito ENUM("Tecnologia", "Arte", "Materiali", "Sport", "Alimentare"),
    EntePromotore VARCHAR(40)
);

CREATE TABLE CITTA (
	Nome VARCHAR(40) PRIMARY KEY,
    Regione VARCHAR(40),
    NumeroAbitanti INT DEFAULT 0
);

CREATE TABLE EDIZIONE (
	Codice INT AUTO_INCREMENT PRIMARY KEY,
    Anno INT,
    NomeFiera VARCHAR(40),
    NomeCitta VARCHAR(40),
    NumeroEspositori INT DEFAULT 0,
    SuperficieTotale INT DEFAULT 0,
    FOREIGN KEY (NomeFiera) REFERENCES FIERA(Nome),
    FOREIGN KEY (NomeCitta) REFERENCES CITTA(Nome)
);

CREATE TABLE ESPOSITORE (
	Codice INT AUTO_INCREMENT PRIMARY KEY,
    NomeAzienda VARCHAR(40),
    Sede VARCHAR(40),
    Tipologia ENUM("Startup", "SME", "Enterprise"),
    PunteggioMedio FLOAT DEFAULT 0,
    FOREIGN KEY (Sede) REFERENCES CITTA(Nome)
);

CREATE TABLE MEMBRO_GIURIA (
	Codice INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(40) NOT NULL,
    Cognome VARCHAR(40) NOT NULL,
    Specializzazione ENUM("Tecnologia", "Arte", "Materiali", "Sport", "Alimentare")
);

CREATE TABLE PARTECIPAZIONE (
	CodiceEspositore INT,
    CodiceEdizione INT,
    MetriQuadri INT DEFAULT 9,
    FOREIGN KEY (CodiceEspositore) REFERENCES ESPOSITORE(Codice),
    FOREIGN KEY (CodiceEdizione) REFERENCES EDIZIONE(Codice)
);

CREATE TABLE VALUTAZIONE (
	Id INT AUTO_INCREMENT PRIMARY KEY,
    CodiceMembro INT,
    CodiceEspositore INT,
    CodiceEdizione INT,
    Voto INT DEFAULT 1,
    DataValutazione DATE NOT NULL,
    FOREIGN KEY (CodiceMembro) REFERENCES MEMBRO_GIURIA(Codice),
    FOREIGN KEY (CodiceEspositore) REFERENCES ESPOSITORE(Codice),
    FOREIGN KEY (CodiceEdizione) REFERENCES EDIZIONE(Codice)
);


# 3) TRIGGER (Come da specifiche, i trigger sono stati collocati PRIMA delle istruzioni di INSERT)
# a)
DELIMITER |
CREATE TRIGGER AggiornaEdizione
AFTER INSERT ON PARTECIPAZIONE
FOR EACH ROW	
BEGIN
	UPDATE EDIZIONE
    SET NumeroEspositori = NumeroEspositori + 1, SuperficieTotale = SuperficieTotale + NEW.MetriQuadri
    WHERE Codice = NEW.CodiceEdizione;
END |

# b)
DELIMITER |
CREATE TRIGGER RipristinaEdizione
BEFORE DELETE ON PARTECIPAZIONE
FOR EACH ROW
BEGIN
	UPDATE EDIZIONE
    SET NumeroEspositori = NumeroEspositori - 1, SuperficieTotale = SuperficieTotale - OLD.MetriQuadri
    WHERE Codice = OLD.CodiceEdizione;
END |

# c)
DELIMITER |
CREATE TRIGGER NormalizzaVoto
BEFORE INSERT ON VALUTAZIONE
FOR EACH ROW
BEGIN
	IF (NEW.Voto > 10) THEN
		SET NEW.Voto = 10;
    ELSEIF (NEW.Voto < 1) THEN
		SET NEW.Voto = 1;
    END IF;
END |

# d)
DELIMITER |
CREATE TRIGGER RicalcolaPunteggio
AFTER INSERT ON VALUTAZIONE
FOR EACH ROW
BEGIN
	UPDATE ESPOSITORE
    SET PunteggioMedio = (SELECT AVG(Voto) FROM VALUTAZIONE WHERE CodiceEspositore = NEW.CodiceEspositore)
    WHERE Codice = NEW.CodiceEspositore;
END |


# 1) POPOLAMENTO TABELLE
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("Info2000","Tecnologia","Confindustria Digitale");
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("SmartTech Expo","Tecnologia","Camera di Commercio Milano");
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("ArteContemporanea","Arte","Fondazione Arti Visive");
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("MaterialiFuturo","Materiali","Associazione Nazionale Materiali");
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("SportLife","Sport","CONI Eventi");
INSERT INTO FIERA(Nome, Ambito, EntePromotore) VALUES ("GustoItalia","Alimentare","Federalimentare");

INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Milano","Lombardia",1371000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Bergamo","Lombardia",120000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Bologna","Emilia-Romagna",392000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Rimini","Emilia-Romagna",150000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Torino","Piemonte",848000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Verona","Veneto",257000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Firenze","Toscana",361000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Roma","Lazio",2750000);
INSERT INTO CITTA(Nome, Regione, NumeroAbitanti) VALUES ("Napoli","Campania",913000);

INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (1,2020,"Info2000","Milano");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (2,2021,"Info2000","Bologna");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (3,2022,"Info2000","Milano");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (4,2023,"Info2000","Roma");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (5,2022,"SmartTech Expo","Milano");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (6,2023,"SmartTech Expo","Bergamo");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (7,2021,"ArteContemporanea","Firenze");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (8,2023,"ArteContemporanea","Firenze");
INSERT INTO EDIZIONE(Codice, Anno, NomeFiera, NomeCitta) VALUES (9,2022,"GustoItalia","Napoli");

INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (1,"Giulia","Rossi","Tecnologia");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (2,"Luca","Bianchi","Tecnologia");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (3,"Sara","Conti","Tecnologia");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (4,"Paolo","Ferrari","Arte");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (5,"Elena","Romano","Arte");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (6,"Marco","Esposito","Materiali");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (7,"Chiara","Ricci","Sport");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (8,"Davide","Marino","Sport");
INSERT INTO MEMBRO_GIURIA(Codice, Nome, Cognome, Specializzazione) VALUES (9,"Francesca","Greco","Alimentare");


# 2) STORED PROCEDURE
# a)
DELIMITER |
CREATE PROCEDURE InserisciEspositore(IN NomeAzienda VARCHAR(40), IN Sede VARCHAR(40), IN Tipologia VARCHAR(40))
BEGIN
	DECLARE SedeOK INT;
    DECLARE NomeAziendaOK INT;
    
    SET SedeOK = (SELECT COUNT(*) FROM CITTA WHERE CITTA.Nome = Sede);
    SET NomeAziendaOK = (SELECT COUNT(*) FROM ESPOSITORE AS E1 WHERE NOT EXISTS (
																			SELECT COUNT(*)
                                                                            FROM ESPOSITORE E2
                                                                            WHERE E1.NomeAzienda <> E2.NomeAzienda AND E1.Sede <> E2.Sede));
    
    IF(SedeOK >0 AND NomeAziendaOK=0 AND (Tipologia="Startup" OR Tipologia="SME" OR Tipologia="Enterprise")) THEN
		INSERT INTO ESPOSITORE(NomeAzienda, Sede, Tipologia) VALUES (NomeAzienda, Sede , Tipologia);
    END IF;
END |

# b)
DELIMITER |
CREATE PROCEDURE InserisciPartecipazione(IN CodiceEspositore INT, IN CodiceEdizione INT, IN MetriQuadri INT)
BEGIN
	DECLARE CodiceEspositoreOK INT;
    DECLARE CodiceEdizioneOK INT;
    DECLARE NumeroEspositoriOK INT;
    
    SET CodiceEspositoreOK = (SELECT COUNT(*) FROM ESPOSITORE WHERE ESPOSITORE.Codice = CodiceEspositore);
    SET CodiceEdizioneOK = (SELECT COUNT(*) FROM EDIZIONE WHERE EDIZIONE.Codice = CodiceEdizione);
    SET NumeroEspositoriOK = (SELECT COUNT(*) FROM EDIZIONE WHERE NumeroEspositori <= 10);
    
    IF (CodiceEspositoreOK>0 AND CodiceEdizioneOK>0 AND (MetriQuadri >= 4 AND MetriQuadri <= 100) AND NumeroEspositoriOK > 0) THEN
		INSERT INTO PARTECIPAZIONE(CodiceEspositore, CodiceEdizione, MetriQuadri) VALUES (CodiceEspositore, CodiceEdizione, MetriQuadri);
    END IF;
END |

# c)
DELIMITER |
CREATE PROCEDURE InserisciValutazione(IN CodiceMembro INT, IN CodiceEspositore INT, IN CodiceEdizione INT, IN Voto INT, IN DataValutazione DATE)
BEGIN
	DECLARE CodiceMembroOK INT;
    DECLARE CodiceEspositoreOK INT;
    DECLARE CodiceEdizioneOK INT;
    
    DECLARE PartecipazioneOK INT;
    DECLARE AmbitoEValutazioneOK INT;
    
    SET CodiceMembroOK = (SELECT COUNT(*) FROM MEMBRO_GIURIA WHERE MEMBRO_GIURIA.Codice = CodiceMembro);
    SET CodiceEspositoreOK = (SELECT COUNT(*) FROM ESPOSITORE WHERE ESPOSITORE.CodiceEspositore = CodiceEspositore);
    SET CodiceEdizioneOK = (SELECT COUNT(*) FROM EDIZIONE WHERE EDIZIONE.CodiceEdizione = CodiceEdizione);
    
    SET PartecipazioneOK = (SELECT COUNT(*) FROM PARTECIPAZIONE WHERE PARTECIPAZIONE.CodiceEspositore = CodiceEspositore AND PARTECIPAZIONE.CodiceEdizione = CodiceEdizione);
    SET AmbitoEValutazioneOK = (SELECT COUNT(*) FROM MEMBRO_GIURIA, ESPOSITORE, EDIZIONE WHERE Specializzazione = ANY (SELECT Ambito FROM FIERA, EDIZIONE WHERE EDIZIONE.Codice = CodiceEdizione) AND (CodiceMembro = CodiceMembro AND ESPOSITORE.Codice <> CodiceEspositore AND EDIZIONE.Codice <> CodiceEdizione));
    
    IF (CodiceMembroOK>0 AND CodiceEspositoreOK>0 AND CodiceEdizione>0 AND PartecipazioneOK>0 AND AmbitoEValutazioneOK>0) THEN
		INSERT INTO VALUTAZIONE(CodiceMembro, CodiceEspositore, CodiceEdizione, Voto, DataValutazione) VALUES (CodiceMembro, CodiceEspositore, CodiceEdizione, Voto, DataValutazione);
    END IF;
END |

# d)
DELIMITER |
CREATE PROCEDURE RimuoviEdizione(IN CodiceEdizioneI INT)
BEGIN
	
END |


# 4) VISTE
# a)
CREATE VIEW LISTA_FIERE_ITINERANTI(Nome, EntePromotore) AS (
	SELECT F.Nome
    FROM FIERA AS F, EDIZIONE AS E, CITTA AS C
    WHERE F.Nome = E.NomeFiera AND E.NomeCitta = C.Nome
    GROUP BY F.Nome
    HAVING COUNT(DISTINCT Regione) > 3
);

# b)
CREATE VIEW LISTA_ESPOSITORI_ASSIDUI(Codice, NomeAzienda, Sede) AS (
	SELECT *
    FROM ESPOSITORE AS ES, PARTECIPAZIONE AS P, EDIZIONE AS ED
    WHERE Sede="Milano" AND (ES.Codice = P.CodiceEspositore AND P.CodiceEdizione = ED.Codice) AND ED.NomeFiera = "Info2000"
);

# c)
CREATE VIEW LISTA_CITTA_OSPITANTI(Nome, Regione, SuperficieComplessiva) AS (
	SELECT *
    FROM CITTA AS C, EDIZIONE AS ED
    WHERE C.Nome = ED.NomeCitta
    GROUP BY C.Nome
	HAVING COUNT(*) >= 2
);

# d)
CREATE VIEW LISTA_ESPOSITORE_TOP(NomeAzienda, Sede) AS (
	SELECT ES.NomeAzienda, ES.Sede
    FROM ESPOSITORE AS ES, PARTECIPAZIONE AS P, EDIZIONE AS ED
    WHERE ES.PunteggioMedio = (SELECT MAX(PunteggioMedio) FROM ESPOSITORE) AND (ES.Codice = P.CodiceEspositore AND P.CodiceEdizione = ED.Codice) AND ED.NomeFiera = "Info2000"
);