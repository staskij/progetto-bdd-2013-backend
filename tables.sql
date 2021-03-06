CREATE TABLE nazione(
	name VARCHAR(80) PRIMARY KEY
);

CREATE TABLE utente(
	userid INTEGER DEFAULT get_first_free_utente() PRIMARY KEY , 
	nome VARCHAR(40), 
	cognome VARCHAR(40) CHECK (cognome IS NOT NULL OR nome IS NOT NULL), 
	cfiscale CHAR(16) NOT NULL CHECK (cfiscale ~ '[A-Za-z0-9]{16}'), 
	indirizzo VARCHAR(70), 
	citta VARCHAR(70),
	nazione_res VARCHAR(80) REFERENCES nazione(name),
	email VARCHAR(100) CHECK (email ~ '' OR email ~ '^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$'), 
	telefono VARCHAR(20) CHECK (telefono ~ '[+]?[0-9]*[/-\\]?[0-9]*')
	);

CREATE TABLE valuta(
	simbolo VARCHAR(3) PRIMARY KEY
);

CREATE TABLE profilo(
	userid INTEGER PRIMARY KEY REFERENCES utente(userid),
	valuta VARCHAR(3) DEFAULT '€' NOT NULL REFERENCES valuta(simbolo),
	username varchar(60) UNIQUE,
	password_hashed varchar(64)
	);

CREATE TABLE categoria_entrata(
	userid INTEGER REFERENCES utente(userid) NOT NULL, 
	nome VARCHAR(40), 
	supercat_nome VARCHAR(40), 
	PRIMARY KEY(userid, nome), 
	FOREIGN KEY(userid, supercat_nome) REFERENCES categoria_entrata(userid, nome)
	);

CREATE TABLE categoria_spesa(
	userid INTEGER REFERENCES utente(userid) NOT NULL, 
	nome VARCHAR(40), 
	supercat_nome VARCHAR(40), 
	PRIMARY KEY(userid, nome), 
	FOREIGN KEY(userid, supercat_nome) REFERENCES categoria_spesa(userid, nome)
	);

CREATE DOMAIN DEPCRED AS VARCHAR CHECK(VALUE IN ('Deposito','Credito'));

CREATE TABLE conto(
	numero INTEGER DEFAULT get_first_free_conto() PRIMARY KEY,
	amm_disp DECIMAL(19,4) NOT NULL,
	tipo DEPCRED NOT NULL,
	tetto_max DECIMAL(19,4) CHECK (tetto_max >=0 AND ((tipo='Credito' AND tetto_max IS NOT NULL) OR (tipo='Deposito' AND tetto_max IS NULL))),
	scadenza_giorni INTERVAL CHECK (scadenza_giorni >= '1 day' AND ((tipo = 'Credito' AND scadenza_giorni IS NOT NULL) OR (tipo = 'Deposito' AND scadenza_giorni IS NULL))),
	userid INTEGER REFERENCES utente(userid) NOT NULL,
	data_creazione DATE NOT NULL,
	conto_di_rif INTEGER CHECK ((tipo = 'Credito' and conto_di_rif IS NOT NULL) OR (tipo = 'Deposito' AND conto_di_rif IS NULL)) REFERENCES conto(numero)
	);

CREATE TABLE spesa(
	conto INTEGER REFERENCES conto(numero) NOT NULL
	,
	id_op INTEGER DEFAULT 0,
	data DATE NOT NULL,
	categoria_user INTEGER,
	categoria_nome VARCHAR(40),
	descrizione VARCHAR(100),
	valore DECIMAL(19,4) NOT NULL CHECK (valore > 0),
	PRIMARY KEY(conto,id_op),
	FOREIGN KEY(categoria_user,categoria_nome) REFERENCES categoria_spesa(userid,nome)
	);

CREATE TABLE entrata(
	conto INTEGER REFERENCES conto(numero),
	id_op INTEGER DEFAULT 0,
	data DATE NOT NULL,
	categoria_user INTEGER,
	categoria_nome VARCHAR(40),
	descrizione VARCHAR(100),
	valore DECIMAL(19,4) NOT NULL CHECK (valore > 0),
	PRIMARY KEY(conto,id_op),
	FOREIGN KEY(categoria_user,categoria_nome) REFERENCES categoria_entrata(userid,nome)
	);


CREATE TABLE bilancio(
	userid INTEGER REFERENCES utente(userid),
	nome varchar(40),
	ammontareprevisto DECIMAL(19,4) NOT NULL CHECK (ammontareprevisto >= 0),
	ammontarerestante DECIMAL(19,4) NOT NULL,
	periodovalidita INTERVAL NOT NULL CHECK (periodovalidita >= '1 day'),
	data_partenza DATE NOT NULL,
	PRIMARY KEY(userid,nome)
	);

CREATE TABLE bilancio_conto(
	userid INTEGER, --no need to reference to user, else double-check
	nome_bil VARCHAR(40),
	numero_conto INTEGER REFERENCES conto(numero),
	PRIMARY KEY(userid,nome_bil,numero_conto),
	FOREIGN KEY(userid,nome_bil) REFERENCES bilancio(userid,nome)
	);

CREATE TABLE bilancio_categoria(
	userid INTEGER, --no need to reference to user, else double-check
	nome_bil VARCHAR(40),
	nome_cat VARCHAR(40),
	PRIMARY KEY(userid,nome_bil,nome_cat),
	FOREIGN KEY(userid,nome_bil) REFERENCES bilancio(userid,nome),
	FOREIGN KEY(userid,nome_cat) REFERENCES categoria_spesa(userid,nome)
	);
