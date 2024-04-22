CREATE DATABASE ex_triggers_08
GO
USE ex_triggers_08
GO
CREATE TABLE produto
(
	codigo			INT				NOT NULL,
	nome			VARCHAR(50)		NOT NULL,
	descricao		VARCHAR(100)	NOT NULL,
	valor_unitario	DECIMAL(7, 2)	NOT NULL
	PRIMARY KEY (codigo)
)
GO
CREATE TABLE estoque
(
	codigo_produto	INT				NOT NULL,
	qtd_estoque		INT				NOT NULL,
	estoque_min		INT				NOT NULL
	PRIMARY KEY (codigo_produto)
	FOREIGN KEY (codigo_produto) REFERENCES produto (codigo)
)
GO
CREATE TABLE venda
(
	nota_fiscal		VARCHAR(20)		NOT NULL,
	codigo_produto	INT				NOT NULL,
	quantidade		INT				NOT NULL
	PRIMARY KEY (nota_fiscal)
	FOREIGN KEY (codigo_produto) REFERENCES produto (codigo)
)

INSERT INTO produto (codigo, nome, descricao, valor_unitario)
VALUES 
(1, 'Camiseta', 'Camiseta de algodão', 29.99),
(2, 'Calça Jeans', 'Calça jeans azul', 49.99),
(3, 'Tênis', 'Tênis esportivo preto', 79.99),
(4, 'Moletom', 'Moletom com capuz', 39.99),
(5, 'Bermuda', 'Bermuda de praia', 19.99)

INSERT INTO estoque (codigo_produto, qtd_estoque, estoque_min)
VALUES 
(1, 50, 10),
(2, 30, 5),
(3, 20, 8),
(4, 40, 15),
(5, 60, 12)

-- Fazer uma TRIGGER AFTER na tabela Venda que, uma vez feito um INSERT, verifique se a quantidade
-- está disponível em estoque. Caso esteja, a venda se concretiza, caso contrário, a venda deverá ser
-- cancelada e uma mensagem de erro deverá ser enviada. A mesma TRIGGER deverá validar, caso a
-- venda se concretize, se o estoque está abaixo do estoque mínimo determinado ou se após a venda,
-- ficará abaixo do estoque considerado mínimo e deverá lançar um print na tela avisando das duas
-- situações.

CREATE TRIGGER t_verifica_estoque ON venda
AFTER INSERT
AS
BEGIN
	
	DECLARE @qtd_min 		INT,
			@qtd_estoque	INT,
			@quantidade		INT,
			@codigo			INT
			
	SELECT @codigo = i.codigo_produto, @quantidade = i.quantidade, @qtd_min = e.estoque_min, @qtd_estoque = e.qtd_estoque 
	FROM estoque e, INSERTED i 
	WHERE i.codigo_produto = e.codigo_produto
	
	IF (@quantidade <= @qtd_estoque)
	BEGIN 
		PRINT 'Venda concluida'
		
		SET @qtd_estoque = @qtd_estoque - @quantidade
		
		IF (@qtd_estoque < @qtd_min)
		BEGIN 
			PRINT 'Quantidade de estoque do produto está abaixo do estoque minimo'
		END
		
		UPDATE estoque 
		SET qtd_estoque = qtd_estoque - i.quantidade
		FROM INSERTED i
		WHERE estoque.codigo_produto = i.codigo_produto
	END
	ELSE 
	BEGIN 
		ROLLBACK TRANSACTION 
		RAISERROR('Quantidade não pode ser maior que o estoque', 16, 1)
	END
END

INSERT INTO venda 
VALUES
('143516783339', 5, 10)

DELETE venda

SELECT * FROM venda


-- Fazer uma UDF (User Defined Function) Multi Statement Table, que apresente, para uma dada nota
-- fiscal, a seguinte saída:
-- (Nota_Fiscal | Codigo_Produto | Nome_Produto | Descricao_Produto | Valor_Unitario | Quan�dade
-- | Valor_Total*)
-- * Considere que Valor_Total = Valor_Unitário * Quantidade

CREATE FUNCTION fn_nota_fiscal (@nt VARCHAR(20))
RETURNS @tabela TABLE
(
	nota_fiscal		VARCHAR(20),
	codigo_produto		INT,
	nome_produto		VARCHAR(50),
	descricao_produto	VARCHAR(100),
	valor_unitario		DECIMAL(7, 2),
	quantidade			INT,
	valor_total		DECIMAL(7, 2)
)
AS
BEGIN
	INSERT INTO @tabela (nota_fiscal, codigo_produto, nome_produto, descricao_produto, valor_unitario, quantidade, valor_total)
	SELECT 
	v.nota_fiscal, 
	p.codigo, 
	p.nome,
	p.descricao,
	p.valor_unitario,
	v.quantidade,
	v.quantidade * p.valor_unitario
	FROM produto p, venda v
	WHERE p.codigo = v.codigo_produto
		AND v.nota_fiscal = @nt
		
	RETURN
END

SELECT * FROM fn_nota_fiscal('1234') 

SELECT * 
FROM produto p, estoque e, venda v
WHERE p.codigo = e.codigo_produto
	AND p.codigo = v.codigo_produto
	
