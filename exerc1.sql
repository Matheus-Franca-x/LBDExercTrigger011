CREATE DATABASE ex_triggers_07
GO
USE ex_triggers_07
GO
CREATE TABLE cliente 
(
	codigo 			INT 			NOT NULL,
	nome 			VARCHAR(70) 	NOT NULL
	PRIMARY KEY(codigo)
)
GO
CREATE TABLE produto 
(
	codigo INT NOT NULL,
	nome VARCHAR(100) NOT NULL,
	preco DECIMAL(7,2) NOT NULL,
	PRIMARY KEY (codigo)
)
GO
CREATE TABLE venda 
(
	codigo_venda 	INT 			NOT NULL,
	codigo_cliente 	INT 			NOT NULL,
	codigo_produto 	INT				NOT NULL,
	valor_total 	DECIMAL(7,2) 	NOT NULL
	PRIMARY KEY (codigo_venda)
	FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo),
	FOREIGN KEY (codigo_produto) REFERENCES produto(codigo)
)
GO
CREATE TABLE pontos 
(
	codigo_cliente 	INT 			NOT NULL,
	total_pontos 	DECIMAL(4,1) 	NOT NULL
	PRIMARY KEY (codigo_cliente)
	FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)

INSERT INTO cliente (codigo, nome)
VALUES 
(1, 'João da Silva'),
(2, 'Maria Oliveira'),
(3, 'José Pereira')

INSERT INTO produto (codigo, nome, preco)
VALUES 
(1, 'Camiseta', 29.99),
(2, 'Calça Jeans', 49.99),
(3, 'Sapato', 79.99)

INSERT INTO venda (codigo_venda, codigo_cliente, codigo_produto, valor_total)
VALUES 
(8, 1, 1, 29.99)

INSERT INTO venda (codigo_venda, codigo_cliente, codigo_produto, valor_total)
VALUES 
(2, 2, 2, 49.99)

INSERT INTO venda (codigo_venda, codigo_cliente, codigo_produto, valor_total)
VALUES 
(3, 3, 3, 79.99)


-- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não
-- venha mais a ser vendido
CREATE TRIGGER t_delpro ON produto
FOR DELETE
AS
BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('Não pode deletar produto', 16, 1)
END

-- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada.

CREATE TRIGGER t_updtven ON venda
FOR UPDATE 
AS
BEGIN
	ROLLBACK TRANSACTION
	RAISERROR('Não pode alterar venda', 16, 1)
END

-- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que
-- comprou e o valor da última compra

CREATE TRIGGER t_updtventable ON venda
INSTEAD OF UPDATE 
AS
BEGIN
	SELECT TOP 1 c.nome, v.valor_total FROM venda v, cliente c
	WHERE v.codigo_cliente = c.codigo
	ORDER BY v.codigo_venda DESC
END

-- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em
-- pontos.

-- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após
-- sua primeira compra

DROP TRIGGER t_insven

CREATE TRIGGER t_insven ON venda
AFTER INSERT 
AS
BEGIN
	IF ((SELECT i.codigo_cliente FROM INSERTED i, pontos p WHERE i.codigo_cliente = p.codigo_cliente) IS NULL)
	BEGIN 
		INSERT INTO pontos (codigo_cliente, total_pontos)
		SELECT codigo_cliente, valor_total * 0.1 FROM INSERTED
	END
	ELSE
	BEGIN
		UPDATE pontos
		SET total_pontos = total_pontos + (i.valor_total * 0.1)
		FROM INSERTED i
		WHERE pontos.codigo_cliente = i.codigo_cliente
	END
END

-- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que
-- ganhou e remove esse 1 ponto da tabela de pontos

CREATE TRIGGER t_ins_ven_rem_ponto ON venda
AFTER INSERT 
AS
BEGIN
	DECLARE @ponto INT
	SELECT @ponto = valor_total * 0.1 FROM INSERTED
	
	IF (@ponto > 1)
	BEGIN
		PRINT 'Parabéns, você ganhou um ponto!'
		
		UPDATE pontos 
		SET total_pontos = total_pontos - 1
		FROM INSERTED i
		WHERE pontos.codigo_cliente = i.codigo_cliente
	END
END

