USE FIERE_AZIENDALI;

#Rimuove le Stored Procedure
SET SQL_SAFE_UPDATES=0;
DROP PROCEDURE IF EXISTS TEST_UNO;
DROP PROCEDURE IF EXISTS TEST_DUE;
DROP PROCEDURE IF EXISTS TEST_TRE;
DROP PROCEDURE IF EXISTS TEST_QUATTRO;
DROP PROCEDURE IF EXISTS TEST_CINQUE;
DROP PROCEDURE IF EXISTS TEST_SEI;
DROP PROCEDURE IF EXISTS TEST_SETTE;
DROP PROCEDURE IF EXISTS TEST_OTTO;
DROP PROCEDURE IF EXISTS TEST_NOVE;
DROP PROCEDURE IF EXISTS TEST_DIECI;
DROP PROCEDURE IF EXISTS TEST_UNDICI;
DROP PROCEDURE IF EXISTS TEST_DODICI;
DROP PROCEDURE IF EXISTS TEST_TREDICI;
DROP PROCEDURE IF EXISTS RIPRISTINA_DB;
DROP PROCEDURE IF EXISTS AGGIUNGI_LOG;
DROP PROCEDURE IF EXISTS STAMPA_LOG;
DROP PROCEDURE IF EXISTS RIEPILOGO_TEST;
DROP TABLE IF EXISTS LOG;


# Variabili, tabelle e funzioni di ausilio
# NON MODIFICARE
SET @NUM_FIERE=6;
SET @NUM_EDIZIONI=9;
SET @NUM_CITTA=9;
SET @NUM_MEMBRI_GIURIA=9;
SET @TEST_ERROR_CONDITION=false;
SET @GLOBAL_ERROR_CONDITION=false;


#-----------------------------------------------------
# Funzioni di logging
CREATE TABLE LOG(
	Id INT AUTO_INCREMENT PRIMARY KEY,
    NumeroTest INT,
    Messaggio VARCHAR(200),
    Esito BOOLEAN);


DELIMITER $
CREATE PROCEDURE AGGIUNGI_LOG(IN TestNo INT, IN Testo VARCHAR(200), IN Ok BOOLEAN)
BEGIN
	INSERT INTO LOG(NumeroTest, Messaggio, Esito) VALUES (TestNo, Testo, Ok);
END $
DELIMITER ;


DELIMITER $
CREATE PROCEDURE RIEPILOGO_TEST(IN NumTest INT)
BEGIN
	DECLARE Messaggio VARCHAR(30);
	IF (@TEST_ERROR_CONDITION=true) THEN
		SET Messaggio=CONCAT(" TEST ",NumTest," FALLITO");
		CALL AGGIUNGI_LOG(NumTest, Messaggio, false);
	ELSE
		SET Messaggio=CONCAT(" TEST ",NumTest," OK");
		CALL AGGIUNGI_LOG(NumTest, Messaggio, true);
	END IF;
    SET @GLOBAL_ERROR_CONDITION=@GLOBAL_ERROR_CONDITION OR @TEST_ERROR_CONDITION;
    SET @TEST_ERROR_CONDITION=false;
END $
DELIMITER ;

DELIMITER $
CREATE PROCEDURE STAMPA_LOG()
BEGIN
	IF @GLOBAL_ERROR_CONDITION=true THEN
		CALL AGGIUNGI_LOG(0, "TEST NON SUPERATO! (debug necessario)", false);
    ELSE
		CALL AGGIUNGI_LOG(0, "TEST INTERAMENTE SUPERATO! (puoi sottomettere)", true);

    END IF;
	SELECT NumeroTest, Messaggio, Esito FROM LOG;
END $
DELIMITER ;

# Funzioni di ripristino DB a valle di modifiche operate dal test
# (l'ordine delle cancellazioni rispetta i vincoli di integrità referenziale)
DELIMITER $
CREATE PROCEDURE RIPRISTINA_DB()
BEGIN
	DELETE FROM VALUTAZIONE;
    DELETE FROM PARTECIPAZIONE;
	DELETE FROM ESPOSITORE;
    UPDATE EDIZIONE SET NumeroEspositori = 0;
    UPDATE EDIZIONE SET SuperficieTotale = 0;
END $
DELIMITER ;

#-----------------------------------------------------


# Test UNO: Verifica il corretto popolamento delle tabelle FIERA, EDIZIONE, CITTA e MEMBRO_GIURIA
DELIMITER $
CREATE PROCEDURE TEST_UNO()
BEGIN
	DECLARE NumFiereInTabella INT DEFAULT 0;
    DECLARE NumEdizioniInTabella INT DEFAULT 0;
    DECLARE NumCittaInTabella INT DEFAULT 0;
    DECLARE NumGiuriaInTabella INT DEFAULT 0;

    SET NumFiereInTabella = (SELECT COUNT(*) FROM FIERA);
    SET NumEdizioniInTabella = (SELECT COUNT(*) FROM EDIZIONE);
    SET NumCittaInTabella = (SELECT COUNT(*) FROM CITTA);
    SET NumGiuriaInTabella = (SELECT COUNT(*) FROM MEMBRO_GIURIA);

	IF (@NUM_FIERE != NumFiereInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella FIERA, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella FIERA, popolamento CORRETTO", true);
    END IF;

    IF (@NUM_EDIZIONI != NumEdizioniInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella EDIZIONE, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella EDIZIONE, popolamento CORRETTO", true);
    END IF;

	IF (@NUM_CITTA != NumCittaInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CITTA, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella CITTA, popolamento CORRETTO", true);
    END IF;

	IF (@NUM_MEMBRI_GIURIA != NumGiuriaInTabella) THEN
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella MEMBRO_GIURIA, popolamento NON corretto", false);
        SET @TEST_ERROR_CONDITION = true;
	ELSE
		CALL AGGIUNGI_LOG(1, "Test popolamento tabella MEMBRO_GIURIA, popolamento CORRETTO", true);
    END IF;

    CALL RIEPILOGO_TEST(1);
END $
DELIMITER ;


# Test DUE: Verifica il corretto funzionamento della procedura InserisciEspositore
DELIMITER $
CREATE PROCEDURE TEST_DUE()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;

    # Tentativo di inserimento di Espositore per citta NON presente nella tabella CITTA
    # L'operazione non dovrebbe essere consentita
    CALL InserisciEspositore("AZ_0", "Catania", "SME");
    SET NumeroRighe=(SELECT COUNT(*) FROM ESPOSITORE);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-1, Test inserimento ESPOSITORE per città inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-1, Test inserimento ESPOSITORE per città inesistente SUPERATO", true);
    END IF;

	# Tentativo di inserimento di Espositore per tipologia NON valida
    # ("Privato" non è più una tipologia ammessa)
    # L'operazione non dovrebbe essere consentita
    CALL InserisciEspositore("AZ_0", "Torino", "Privato");
    SET NumeroRighe=(SELECT COUNT(*) FROM ESPOSITORE);
    IF (NumeroRighe>0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-2, Test inserimento ESPOSITORE per tipologia inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-2, Test inserimento ESPOSITORE per tipologia inesistente SUPERATO", true);
    END IF;

	# Tentativo di inserimento di Espositore per tipologia e sede valida
    # L'operazione  dovrebbe essere consentita
	CALL InserisciEspositore("AZ_0", "Torino", "Startup");
    SET NumeroRighe=(SELECT COUNT(*) FROM ESPOSITORE);
    IF (NumeroRighe=0) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-3, Test inserimento ESPOSITORE valido NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-3, Test inserimento ESPOSITORE valido SUPERATO", true);
    END IF;

	# Tentativo di inserimento di un Espositore già presente (stesso NomeAzienda e stessa Sede)
    # L'operazione NON dovrebbe essere consentita: in tabella deve restare una sola riga
	CALL InserisciEspositore("AZ_0", "Torino", "SME");
    SET NumeroRighe=(SELECT COUNT(*) FROM ESPOSITORE);
    IF (NumeroRighe<>1) THEN
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-4, Test inserimento ESPOSITORE duplicato NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(2, "Procedura 2.A-4, Test inserimento ESPOSITORE duplicato SUPERATO", true);
    END IF;

    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(2);
END $
DELIMITER ;



# Test TRE: Verifica il corretto funzionamento della procedura InserisciPartecipazione
DELIMITER $
CREATE PROCEDURE TEST_TRE()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
    DECLARE CodiceE INT;
    DECLARE i INT DEFAULT 0;
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
    SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));

    # Tentativo di inserimento di una PARTECIPAZIONE per espositore non presente nella tabella
    # L'operazione NON deve essere consentita
	CALL InserisciPartecipazione(-1, 1, 10);
    SET NumeroRighe=(SELECT COUNT(*) FROM PARTECIPAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-1, Test inserimento PARTECIPAZIONE per espositore inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-1, Test inserimento PARTECIPAZIONE per espositore inesistente SUPERATO", true);
    END IF;

	# Tentativo di inserimento di una PARTECIPAZIONE per edizione non presente nella tabella
    # L'operazione NON deve essere consentita
    CALL InserisciPartecipazione(CodiceE, -1, 10);
    SET NumeroRighe=(SELECT COUNT(*) FROM PARTECIPAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-2, Test inserimento PARTECIPAZIONE per edizione inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-2, Test inserimento PARTECIPAZIONE per edizione inesistente SUPERATO", true);
    END IF;

	# Tentativo di inserimento di una PARTECIPAZIONE con MetriQuadri fuori dall'intervallo [4,100]
    # L'operazione NON deve essere consentita (si provano entrambi gli estremi)
    CALL InserisciPartecipazione(CodiceE, 1, 3);
    CALL InserisciPartecipazione(CodiceE, 1, 101);
    SET NumeroRighe=(SELECT COUNT(*) FROM PARTECIPAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-3, Test inserimento PARTECIPAZIONE per MetriQuadri non validi NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-3, Test inserimento PARTECIPAZIONE per MetriQuadri non validi SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una PARTECIPAZIONE per edizione/espositore presente nella tabella
    # L'operazione deve essere consentita
    CALL InserisciPartecipazione(CodiceE, 1, 10);
    SET NumeroRighe=(SELECT COUNT(*) FROM PARTECIPAZIONE);
    IF (NumeroRighe = 0) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-4, Test inserimento PARTECIPAZIONE valido NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-4, Test inserimento PARTECIPAZIONE valido SUPERATO", true);
    END IF;

    # Vengono inseriti 10 espositori che partecipano all'edizione con codice 2 (edizione piena)
    WHILE (i < 10) DO
		CALL InserisciEspositore(CONCAT("AZ_P", i), "Milano", "SME");
		SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = CONCAT("AZ_P", i)));
		CALL InserisciPartecipazione(CodiceE, 2, 10);
		SET i = i + 1;
	END WHILE;
    # Tentativo di inserimento di un undicesimo espositore nell'edizione con codice 2
    # L'operazione NON deve essere consentita: le partecipazioni all'edizione 2 devono restare 10
    CALL InserisciEspositore("AZ_P10", "Milano", "SME");
    SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_P10"));
    CALL InserisciPartecipazione(CodiceE, 2, 10);
    SET NumeroRighe=(SELECT COUNT(*) FROM PARTECIPAZIONE WHERE (CodiceEdizione = 2));
    IF (NumeroRighe <> 10) THEN
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-5, Test inserimento PARTECIPAZIONE per edizione piena NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(3, "Procedura 2.B-5, Test inserimento PARTECIPAZIONE per edizione piena SUPERATO", true);
    END IF;

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(3);
END $
DELIMITER ;


# Test QUATTRO: Verifica il corretto funzionamento della procedura InserisciValutazione
# Nota: le edizioni con codice 1 e 2 sono della fiera Info2000 (ambito Tecnologia);
# i membri con codice 1 e 2 sono specializzati in Tecnologia, il membro 7 in Sport
DELIMITER $
CREATE PROCEDURE TEST_QUATTRO()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
	DECLARE CodiceE INT;
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
    SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));

    # Tentativo di inserimento di una VALUTAZIONE per membro della giuria inesistente
    # L'operazione NON deve essere consentita
    CALL InserisciValutazione(-1, CodiceE, 1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-1, Test procedura InserisciValutazione per membro inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-1, Test procedura InserisciValutazione per membro inesistente SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una VALUTAZIONE per espositore inesistente
    # L'operazione NON deve essere consentita
    CALL InserisciValutazione(1, -1, 1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-2, Test procedura InserisciValutazione per espositore inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-2, Test procedura InserisciValutazione per espositore inesistente SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una VALUTAZIONE per edizione inesistente
    # L'operazione NON deve essere consentita
    CALL InserisciValutazione(1, CodiceE, -1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-3, Test procedura InserisciValutazione per edizione inesistente NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-3, Test procedura InserisciValutazione per edizione inesistente SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una VALUTAZIONE di un espositore che non ha partecipato all'edizione
    # L'operazione NON deve essere consentita
    # L'espositore con CodiceE non ha (ancora) partecipato all'edizione con codice 1
    CALL InserisciValutazione(1, CodiceE, 1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-4, Test procedura InserisciValutazione per partecipazione non valida NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-4, Test procedura InserisciValutazione per partecipazione non valida SUPERATO", true);
    END IF;

	# Tentativo di inserimento di una VALUTAZIONE da parte di un membro con specializzazione diversa
    # dall'ambito della fiera (membro 7 = Sport, edizione 1 = Info2000 = Tecnologia)
    # L'operazione NON deve essere consentita
    CALL InserisciPartecipazione(CodiceE, 1, 10);
    CALL InserisciValutazione(7, CodiceE, 1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe > 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-5, Test procedura InserisciValutazione per specializzazione non compatibile NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-5, Test procedura InserisciValutazione per specializzazione non compatibile SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una VALUTAZIONE valida
    # L'operazione deve essere consentita
    CALL InserisciValutazione(1, CodiceE, 1, 8, "2020-05-10");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe = 0) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-6, Test procedura InserisciValutazione per riga valida NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-6, Test procedura InserisciValutazione per riga valida SUPERATO", true);
    END IF;

    # Tentativo di inserimento di una seconda VALUTAZIONE dello stesso membro,
    # per lo stesso espositore e nella stessa edizione
    # L'operazione NON deve essere consentita: in tabella deve restare una sola riga
    CALL InserisciValutazione(1, CodiceE, 1, 5, "2020-05-11");
    SET NumeroRighe=(SELECT COUNT(*) FROM VALUTAZIONE);
    IF (NumeroRighe <> 1) THEN
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-7, Test procedura InserisciValutazione per valutazione duplicata NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(4, "Procedura 2.C-7, Test procedura InserisciValutazione per valutazione duplicata SUPERATO", true);
    END IF;

    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(4);

END $
DELIMITER ;


# Test CINQUE: Verifica il corretto funzionamento della procedura RimuoviEdizione
DELIMITER $
CREATE PROCEDURE TEST_CINQUE()
BEGIN
	DECLARE NumeroRighe INT DEFAULT 0;
    DECLARE CodiceE INT;
    DECLARE CodiceEd INT;

	# Vengono inseriti 2 espositori, che partecipano all'edizione con codice 1
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
	CALL InserisciEspositore("AZ_1", "Milano", "SME");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
    # L'espositore AZ_1 riceve una valutazione nell'edizione con codice 1
    CALL InserisciValutazione(1, CodiceE, 1, 7, "2020-05-10");

    # Tentativo di rimozione dell'edizione con codice 1, che ha delle valutazioni
    # L'operazione NON deve essere consentita: le edizioni devono restare @NUM_EDIZIONI
    CALL RimuoviEdizione(1);
    SET NumeroRighe=(SELECT COUNT(*) FROM EDIZIONE);
    IF (NumeroRighe <> @NUM_EDIZIONI) THEN
		CALL AGGIUNGI_LOG(5, "Procedura 2.D-1, Test procedura RimuoviEdizione per edizione con valutazioni NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(5, "Procedura 2.D-1, Test procedura RimuoviEdizione per edizione con valutazioni SUPERATO", true);
    END IF;

    # Viene creata una nuova edizione di prova, a cui partecipano i 2 espositori (senza valutazioni)
    INSERT INTO EDIZIONE(Anno, NomeFiera, NomeCitta) VALUES (2030, "SportLife", "Roma");
    SET CodiceEd = (SELECT MAX(Codice) FROM EDIZIONE);
    SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
    CALL InserisciPartecipazione(CodiceE, CodiceEd, 10);
    SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
    CALL InserisciPartecipazione(CodiceE, CodiceEd, 10);

    # Viene rimossa l'edizione di prova
    # Devo trovare @NUM_EDIZIONI edizioni e nessuna partecipazione relativa all'edizione rimossa
    CALL RimuoviEdizione(CodiceEd);
    SET NumeroRighe=(SELECT COUNT(*) FROM EDIZIONE) + (SELECT COUNT(*) FROM PARTECIPAZIONE WHERE (CodiceEdizione = CodiceEd));
    IF (NumeroRighe <> @NUM_EDIZIONI) THEN
		CALL AGGIUNGI_LOG(5, "Procedura 2.D-2, Test procedura RimuoviEdizione NON SUPERATO", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(5, "Procedura 2.D-2, Test procedura RimuoviEdizione SUPERATO", true);
    END IF;

    # Rimuove l'edizione di prova, nel caso in cui la procedura non l'abbia rimossa
    DELETE FROM PARTECIPAZIONE WHERE (CodiceEdizione = CodiceEd);
    DELETE FROM EDIZIONE WHERE (Codice = CodiceEd);

    CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(5);

END $
DELIMITER ;



# Test SEI: Verifica il corretto funzionamento del trigger AggiornaEdizione
DELIMITER $
CREATE PROCEDURE TEST_SEI()
BEGIN
	DECLARE Totale INT;
    DECLARE Superficie INT;
    DECLARE CodiceE INT;

	# Viene inserito un primo espositore, che partecipa all'edizione con codice 1 con 10 mq
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
    # Viene inserito un secondo espositore, che partecipa all'edizione con codice 1 con 20 mq
	CALL InserisciEspositore("AZ_1", "Milano", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
	CALL InserisciPartecipazione(CodiceE, 1, 20);
    # Viene inserito un terzo espositore, che partecipa all'edizione con codice 1 con 30 mq
	CALL InserisciEspositore("AZ_2", "Roma", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_2"));
	CALL InserisciPartecipazione(CodiceE, 1, 30);

    # Vengono letti i valori di NumeroEspositori e SuperficieTotale per l'edizione con codice 1
    SET Totale = (SELECT NumeroEspositori FROM EDIZIONE WHERE (Codice = 1));
    SET Superficie = (SELECT SuperficieTotale FROM EDIZIONE WHERE (Codice = 1));

    # Totale deve essere pari a 3 e Superficie a 60 (=10+20+30), come conseguenza dell'esecuzione del Trigger
    IF ((Totale <> 3) OR (Superficie <> 60)) THEN
		CALL AGGIUNGI_LOG(6, "Trigger 3.A, Test risultato trigger AggiornaEdizione NON SUPERATO: risultato diverso da atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(6, "Trigger 3.A, Test risultato trigger AggiornaEdizione SUPERATO", true);
	END IF;

    CALL RIPRISTINA_DB();
	CALL RIEPILOGO_TEST(6);
END $
DELIMITER ;


# Test SETTE: Verifica il corretto funzionamento del trigger RipristinaEdizione
DELIMITER $
CREATE PROCEDURE TEST_SETTE()
BEGIN
	DECLARE Totale INT;
    DECLARE Superficie INT;
    DECLARE CodiceE INT;

	# Viene inserito un primo espositore, che partecipa all'edizione con codice 1 con 10 mq
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
    # Viene inserito un secondo espositore, che partecipa all'edizione con codice 1 con 20 mq
	CALL InserisciEspositore("AZ_1", "Milano", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
	CALL InserisciPartecipazione(CodiceE, 1, 20);
    # Viene inserito un terzo espositore, che partecipa all'edizione con codice 1 con 30 mq
	CALL InserisciEspositore("AZ_2", "Roma", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_2"));
	CALL InserisciPartecipazione(CodiceE, 1, 30);
    # Viene rimossa la partecipazione dell'ultimo espositore
	DELETE FROM PARTECIPAZIONE WHERE ((CodiceEspositore = CodiceE) AND (CodiceEdizione = 1));
	# Vengono letti i valori di NumeroEspositori e SuperficieTotale per l'edizione con codice 1
    SET Totale = (SELECT NumeroEspositori FROM EDIZIONE WHERE (Codice = 1));
    SET Superficie = (SELECT SuperficieTotale FROM EDIZIONE WHERE (Codice = 1));
    # Totale deve essere pari a 2 (=3 inseriti - 1 rimosso) e Superficie a 30 (=60-30),
    # come conseguenza dell'esecuzione del Trigger
    IF ((Totale <> 2) OR (Superficie <> 30)) THEN
		CALL AGGIUNGI_LOG(7, "Trigger 3.B, Test risultato trigger RipristinaEdizione NON SUPERATO: risultato diverso da atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(7, "Trigger 3.B, Test risultato trigger RipristinaEdizione SUPERATO", true);
	END IF;

    CALL RIPRISTINA_DB();
	CALL RIEPILOGO_TEST(7);
END $
DELIMITER ;


# Test OTTO: Verifica il corretto funzionamento del trigger NormalizzaVoto
DELIMITER $
CREATE PROCEDURE TEST_OTTO()
BEGIN
	DECLARE VotoMax INT;
    DECLARE VotoMin INT;
    DECLARE CodiceE INT;

	# Viene inserito un espositore, che partecipa all'edizione con codice 1
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
    # Viene inserita una prima valutazione per quell'espositore, pari a 15 (deve diventare 10)
	CALL InserisciValutazione(1, CodiceE, 1, 15, "2020-05-10");
	# Viene inserita una seconda valutazione per quell'espositore, pari a -5 (deve diventare 1)
	CALL InserisciValutazione(2, CodiceE, 1, -5, "2020-05-10");

	# Vengono letti il voto massimo e il voto minimo presenti in VALUTAZIONE
    SET VotoMax = (SELECT MAX(Voto) FROM VALUTAZIONE);
    SET VotoMin = (SELECT MIN(Voto) FROM VALUTAZIONE);

    # VotoMax deve essere pari a 10 e VotoMin a 1, come conseguenza dell'esecuzione del Trigger
    IF ((VotoMax IS NULL) OR (VotoMax <> 10) OR (VotoMin <> 1)) THEN
		CALL AGGIUNGI_LOG(8, "Trigger 3.C, Test risultato trigger NormalizzaVoto NON SUPERATO: risultato diverso da atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(8, "Trigger 3.C, Test risultato trigger NormalizzaVoto SUPERATO", true);
	END IF;

    CALL RIPRISTINA_DB();
	CALL RIEPILOGO_TEST(8);
END $
DELIMITER ;


# Test NOVE: Verifica il corretto funzionamento del trigger RicalcolaPunteggio
DELIMITER $
CREATE PROCEDURE TEST_NOVE()
BEGIN
	DECLARE Totale FLOAT;
    DECLARE CodiceE INT;

	# Viene inserito un espositore, che partecipa alle edizioni con codice 1 e 2
	CALL InserisciEspositore("AZ_0", "Torino", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
	CALL InserisciPartecipazione(CodiceE, 2, 10);
    # Vengono inserite due valutazioni nell'edizione 1, pari a 10 e 6
	CALL InserisciValutazione(1, CodiceE, 1, 10, "2020-05-10");
	CALL InserisciValutazione(2, CodiceE, 1, 6, "2020-05-10");
    # Viene inserita una valutazione nell'edizione 2, pari a 5
	CALL InserisciValutazione(1, CodiceE, 2, 5, "2021-05-10");

	# Viene letto il valore di PunteggioMedio per l'espositore
    SET Totale = (SELECT PunteggioMedio FROM ESPOSITORE WHERE (Codice = CodiceE));

    # Totale deve essere pari a 7.0 ((10+6+5)/3, su tutte le edizioni), come conseguenza dell'esecuzione del Trigger
    IF ((Totale > 7.01) OR (Totale < 6.99)) THEN
		CALL AGGIUNGI_LOG(9, "Trigger 3.D, Test risultato trigger RicalcolaPunteggio NON SUPERATO: risultato diverso da atteso", false);
        SET @TEST_ERROR_CONDITION=true;
    ELSE
		CALL AGGIUNGI_LOG(9, "Trigger 3.D, Test risultato trigger RicalcolaPunteggio SUPERATO", true);
	END IF;

    CALL RIPRISTINA_DB();
	CALL RIEPILOGO_TEST(9);
END $
DELIMITER ;



# Test DIECI: Verifica il corretto funzionamento della vista LISTA_FIERE_ITINERANTI
DELIMITER $
CREATE PROCEDURE TEST_DIECI()
BEGIN
	DECLARE NomeF VARCHAR(40);
    DECLARE EnteF VARCHAR(40);
    DECLARE NumeroRighe INT DEFAULT 0;
	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_FIERE_ITINERANTI ORDER BY Nome);

    # Dentro la vista, ci deve essere solo una riga: <Info2000> (Lombardia, Emilia-Romagna, Lazio).
    # SmartTech Expo (solo Lombardia), ArteContemporanea (solo Toscana) e GustoItalia (solo Campania)
    # NON devono comparire
    SET NumeroRighe = (SELECT COUNT(*) FROM LISTA_FIERE_ITINERANTI);
	OPEN myCursor;
    FETCH myCursor INTO NomeF, EnteF;
    CLOSE myCursor;

    # Controlla il valore della variabile NomeF e il numero di righe
    IF ((NomeF = "Info2000") AND (NumeroRighe = 1)) THEN
		CALL AGGIUNGI_LOG(10, "Vista 4.A, Test risultato vista LISTA_FIERE_ITINERANTI SUPERATO", true);
    ELSE
		CALL AGGIUNGI_LOG(10, "Vista 4.A, Test risultato vista LISTA_FIERE_ITINERANTI NON SUPERATO: risultato diverso da atteso", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(10);
END $
DELIMITER ;

# Test UNDICI: Verifica il corretto funzionamento della vista LISTA_ESPOSITORI_ASSIDUI
DELIMITER $
CREATE PROCEDURE TEST_UNDICI()
BEGIN
	DECLARE CodiceE INT;
    DECLARE Codice INT;
    DECLARE NomeE VARCHAR(40);
    DECLARE SedeE VARCHAR(40);
    DECLARE NumeroRighe INT DEFAULT 0;

	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_ESPOSITORI_ASSIDUI);

    # Il primo espositore è di Milano e partecipa a tutte le edizioni di Info2000 (codici 1-4)
    CALL InserisciEspositore("AZ_0", "Milano", "Enterprise");
	SET CodiceE = (SELECT ES.Codice FROM ESPOSITORE AS ES WHERE (ES.NomeAzienda = "AZ_0"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
	CALL InserisciPartecipazione(CodiceE, 2, 10);
	CALL InserisciPartecipazione(CodiceE, 3, 10);
	CALL InserisciPartecipazione(CodiceE, 4, 10);
	# Il secondo espositore è di Milano ma NON partecipa all'edizione di Info2000 con codice 4
    CALL InserisciEspositore("AZ_1", "Milano", "Enterprise");
	SET CodiceE = (SELECT ES.Codice FROM ESPOSITORE AS ES WHERE (ES.NomeAzienda = "AZ_1"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
	CALL InserisciPartecipazione(CodiceE, 2, 10);
	CALL InserisciPartecipazione(CodiceE, 3, 10);
    # Il terzo espositore partecipa a tutte le edizioni di Info2000, ma è di Bologna
    CALL InserisciEspositore("AZ_2", "Bologna", "Enterprise");
	SET CodiceE = (SELECT ES.Codice FROM ESPOSITORE AS ES WHERE (ES.NomeAzienda = "AZ_2"));
	CALL InserisciPartecipazione(CodiceE, 1, 10);
	CALL InserisciPartecipazione(CodiceE, 2, 10);
	CALL InserisciPartecipazione(CodiceE, 3, 10);
	CALL InserisciPartecipazione(CodiceE, 4, 10);

    # Dentro la vista, ci deve essere solo una riga con valore <AZ_0>
    SET NumeroRighe = (SELECT COUNT(*) FROM LISTA_ESPOSITORI_ASSIDUI);
	OPEN myCursor;
    FETCH myCursor INTO Codice, NomeE, SedeE;
    CLOSE myCursor;

    # Controlla il valore della variabile NomeE e il numero di righe
    IF ((NomeE = "AZ_0") AND (NumeroRighe = 1)) THEN
		CALL AGGIUNGI_LOG(11, "Vista 4.B, Test risultato vista LISTA_ESPOSITORI_ASSIDUI SUPERATO", true);
    ELSE
		CALL AGGIUNGI_LOG(11, "Vista 4.B, Test risultato vista LISTA_ESPOSITORI_ASSIDUI NON SUPERATO: risultato diverso da atteso", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(11);
END $
DELIMITER ;




# Test DODICI: Verifica il corretto funzionamento della vista LISTA_CITTA_OSPITANTI
# Nota: Milano ospita le edizioni 1, 3, 5; Firenze le edizioni 7, 8; tutte le altre città
# ospitano al più una edizione (Bologna: 2, Roma: 4, Bergamo: 6, Napoli: 9)
DELIMITER $
CREATE PROCEDURE TEST_DODICI()
BEGIN

	DECLARE CodiceE INT;
    DECLARE NomeC VARCHAR(40);
    DECLARE RegioneC VARCHAR(40);
    DECLARE SuperficieC INT;
    DECLARE NumeroRighe INT DEFAULT 0;
    DECLARE NumeroRigheTotali INT DEFAULT 0;

	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_CITTA_OSPITANTI WHERE (Nome = "Firenze"));

    # Inserisce espositore che partecipa alle 2 edizioni svolte a Firenze (codici 7 e 8), con 20 e 30 mq
    CALL InserisciEspositore("AZ_0", "Bologna", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
    CALL InserisciPartecipazione(CodiceE, 7, 20);
    CALL InserisciPartecipazione(CodiceE, 8, 30);

    # Inserisce espositore che partecipa all'unica edizione svolta a Roma (codice 4), con 50 mq
    CALL InserisciEspositore("AZ_1", "Roma", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
    CALL InserisciPartecipazione(CodiceE, 4, 50);

    # Dentro la vista, la riga di <Firenze> deve avere SuperficieComplessiva pari a 50 (=20+30)
    # mentre <Roma> NON deve comparire (ha ospitato una sola edizione).
    # In totale la vista deve contenere 2 righe: <Milano> e <Firenze>
	OPEN myCursor;
	FETCH myCursor INTO NomeC, RegioneC, SuperficieC;
	CLOSE myCursor;
    SET NumeroRighe = (SELECT COUNT(*) FROM LISTA_CITTA_OSPITANTI WHERE (Nome = "Roma"));
    SET NumeroRigheTotali = (SELECT COUNT(*) FROM LISTA_CITTA_OSPITANTI);

    # Controlla il valore delle variabili NomeC e SuperficieC e il numero di righe
    IF ((NomeC = "Firenze") AND (SuperficieC = 50) AND (NumeroRighe = 0) AND (NumeroRigheTotali = 2)) THEN
		CALL AGGIUNGI_LOG(12, "Vista 4.C, Test risultato vista LISTA_CITTA_OSPITANTI SUPERATO", true);
    ELSE
		CALL AGGIUNGI_LOG(12, "Vista 4.C, Test risultato vista LISTA_CITTA_OSPITANTI NON SUPERATO: risultato diverso da atteso", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(12);

END $
DELIMITER ;

# Test TREDICI: Verifica il corretto funzionamento della vista LISTA_ESPOSITORE_TOP
DELIMITER $
CREATE PROCEDURE TEST_TREDICI()
BEGIN

	DECLARE CodiceE INT;
    DECLARE NomeE VARCHAR(40);
    DECLARE SedeE VARCHAR(40);
    DECLARE NumeroRighe INT DEFAULT 0;

	DECLARE myCursor CURSOR FOR (SELECT * FROM LISTA_ESPOSITORE_TOP);

    # Inserisce espositore che partecipa a Info2000 edizione 2022 (codice 3), con voto medio 7 (=(6+8)/2)
    CALL InserisciEspositore("AZ_0", "Bologna", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_0"));
    CALL InserisciPartecipazione(CodiceE, 3, 10);
    CALL InserisciValutazione(1, CodiceE, 3, 6, "2022-05-10");
    CALL InserisciValutazione(2, CodiceE, 3, 8, "2022-05-10");

    # Inserisce espositore che partecipa a Info2000 edizione 2022 (codice 3), con voto medio 8 (=(9+7)/2)
    CALL InserisciEspositore("AZ_1", "Roma", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_1"));
    CALL InserisciPartecipazione(CodiceE, 3, 10);
	CALL InserisciValutazione(1, CodiceE, 3, 9, "2022-05-10");
    CALL InserisciValutazione(2, CodiceE, 3, 7, "2022-05-10");

    # Inserisce espositore che partecipa a Info2000 edizione 2021 (codice 2), con voto medio 10
    # Non deve essere considerato, perché l'edizione non è quella del 2022
    CALL InserisciEspositore("AZ_2", "Milano", "Enterprise");
	SET CodiceE = (SELECT Codice FROM ESPOSITORE WHERE (NomeAzienda = "AZ_2"));
    CALL InserisciPartecipazione(CodiceE, 2, 10);
	CALL InserisciValutazione(1, CodiceE, 2, 10, "2021-05-10");

    # Dentro la vista, ci deve essere solo una riga del secondo espositore <AZ_1, Roma>
    SET NumeroRighe = (SELECT COUNT(*) FROM LISTA_ESPOSITORE_TOP);
	OPEN myCursor;
	FETCH myCursor INTO NomeE, SedeE;
	CLOSE myCursor;

    # Controlla il valore delle variabili NomeE e SedeE
    IF ((NomeE = "AZ_1") AND (SedeE = "Roma") AND (NumeroRighe = 1)) THEN
		CALL AGGIUNGI_LOG(13, "Vista 4.D, Test risultato vista LISTA_ESPOSITORE_TOP SUPERATO", true);
    ELSE
		CALL AGGIUNGI_LOG(13, "Vista 4.D, Test risultato vista LISTA_ESPOSITORE_TOP NON SUPERATO: risultato diverso da atteso", false);
		SET @TEST_ERROR_CONDITION=true;
    END IF;

	CALL RIPRISTINA_DB();
    CALL RIEPILOGO_TEST(13);

END $
DELIMITER ;



#--------------------------------------------------------------------

# Il codice qui sotto esegue le procedure del test
TRUNCATE LOG;
CALL RIPRISTINA_DB();

# Esercizio 1. Popolamento tabelle
CALL TEST_UNO();
# Esercizio 2.A. Stored Procedure InserisciEspositore
CALL TEST_DUE();
# Esercizio 2.B. Stored Procedure InserisciPartecipazione
CALL TEST_TRE();
# Esercizio 2.C. Stored Procedure InserisciValutazione
CALL TEST_QUATTRO();
# Esercizio 2.D. Stored Procedure RimuoviEdizione
CALL TEST_CINQUE();
# Esercizio 3.A. Trigger AggiornaEdizione
CALL TEST_SEI();
# Esercizio 3.B. Trigger RipristinaEdizione
CALL TEST_SETTE();
# Esercizio 3.C. Trigger NormalizzaVoto
CALL TEST_OTTO();
# Esercizio 3.D. Trigger RicalcolaPunteggio
CALL TEST_NOVE();
# Esercizio 4.A. Vista LISTA_FIERE_ITINERANTI
CALL TEST_DIECI();
# Esercizio 4.B. Vista LISTA_ESPOSITORI_ASSIDUI
CALL TEST_UNDICI();
# Esercizio 4.C. Vista LISTA_CITTA_OSPITANTI
CALL TEST_DODICI();
# Esercizio 4.D. Vista LISTA_ESPOSITORE_TOP
CALL TEST_TREDICI();
# Stampa il risultato finale
CALL STAMPA_LOG();
# Svuota Tabelle e ripristina stato pre-test
CALL RIPRISTINA_DB();


# Rimuove le procedure di test dal db
DROP TABLE LOG;
DROP PROCEDURE IF EXISTS TEST_UNO;
DROP PROCEDURE IF EXISTS TEST_DUE;
DROP PROCEDURE IF EXISTS TEST_TRE;
DROP PROCEDURE IF EXISTS TEST_QUATTRO;
DROP PROCEDURE IF EXISTS TEST_CINQUE;
DROP PROCEDURE IF EXISTS TEST_SEI;
DROP PROCEDURE IF EXISTS TEST_SETTE;
DROP PROCEDURE IF EXISTS TEST_OTTO;
DROP PROCEDURE IF EXISTS TEST_NOVE;
DROP PROCEDURE IF EXISTS TEST_DIECI;
DROP PROCEDURE IF EXISTS TEST_UNDICI;
DROP PROCEDURE IF EXISTS TEST_DODICI;
DROP PROCEDURE IF EXISTS TEST_TREDICI;
DROP PROCEDURE IF EXISTS RIPRISTINA_DB;
DROP PROCEDURE IF EXISTS AGGIUNGI_LOG;
DROP PROCEDURE IF EXISTS STAMPA_LOG;
DROP PROCEDURE IF EXISTS RIEPILOGO_TEST;
