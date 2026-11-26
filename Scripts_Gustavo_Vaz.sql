-- 1)Total de Vendas por Região
select 
	case
		when "Região" is null then 'Total Geral'
		else CAST("Região" as VARCHAR)
	end as Região,	
	--COALESCE("Região", 'Total') AS Região,
	SUM(("Quantidade" * "Preço Unitário")- "Desconto Aplicado") as valor_total
from 
	public.raw_data
group by 
	ROLLUP(Região)
order by  
	 Região


-- 2)Produto mais vendido por Categoria
WITH ProdutosRanking AS (
  SELECT
    "Categoria do Produto",
    "Preço Unitário" ,
    "Produto",
    SUM("Quantidade") AS qtd_vendida,
    ROW_NUMBER() OVER (
      PARTITION BY "Categoria do Produto"
      ORDER BY SUM("Quantidade") DESC
    ) AS ranking
  FROM 
  	public.raw_data
  GROUP BY 
  	"Categoria do Produto", 
  	"Produto", 
  	"Preço Unitário" 
)

SELECT
  	"Categoria do Produto",
  	"Produto",
  	"Preço Unitário" ,
  	qtd_vendida
FROM 
	ProdutosRanking
WHERE 
	ranking = 1
ORDER BY 
	"Categoria do Produto"


--3) Qtd de Clientes que fizeram mais de 2 compras no mesmo mês
with   maiorqueduas as (
	select  
		"Nome do Cliente",
		extract(month from to_date("Data da Venda", 'MM/DD/YYYY')) as mes,
	   	extract(YEAR from to_date("Data da Venda", 'MM/DD/YYYY')) as ano,
	   	count("ID da Transação") as nro_compras
	from 
		raw_data
	group by
		"Nome do Cliente", 
		mes, 
		ano
	having 
		count("ID da Transação") > 2
	order by 
		ano, 
		mes, 
		nro_compras
) 

select  mes,  
		COUNT("Nome do Cliente") as qtd_clientes
from 
	maiorqueduas
group by 
	rollup(mes)
order by 
	mes

-- 4)Trimestre e Mês mais Lucrativos
-- Trimestre
select
  CEIL(extract(month from to_date("Data da Venda", 'MM/DD/YYYY')) / 3.0) AS trimestre,
  SUM(("Quantidade" * "Preço Unitário") - "Desconto Aplicado") as Vendas_Acumuladas
FROM 
	public.raw_data
GROUP BY  
	trimestre
ORDER BY 
	Vendas_Acumuladas DESC
limit 1

--Mês
select 	
	extract(month from to_date("Data da Venda", 'MM/DD/YYYY')) as mes,
	SUM(("Quantidade" * "Preço Unitário") - "Desconto Aplicado") as Vendas_Acumuladas
from 
	public.raw_data 
group by 
	mes
order by 
	Vendas_Acumuladas DESC
limit 1


--5) Produtos com mais desconto aplicado
select 	"Produto" , 
		 "Preço Unitário" ,
		SUM("Quantidade") AS qtd_vendida,
		SUM("Desconto Aplicado") as Total_desconto_aplicado
from 
	raw_data  
group by 
	"Produto" , 
	"Preço Unitário" 
order by 
	total_desconto_aplicado  desc 
limit 1

--6) Cliente que mais gastou na semana pré natal

with semana_passada as(
	select 	
		"Nome do Cliente",
		"Data de Nascimento",
		"Quantidade",
		 "Preço Unitário",
		"Desconto Aplicado",
		SUM(("Quantidade" * "Preço Unitário") - "Desconto Aplicado") as Vendas_Acumuladas,
		"Data da Venda"
	from 
		raw_data 
	group by 
		"Nome do Cliente", 
		"Data da Venda", 
		"Quantidade",
		"Preço Unitário",
		"Desconto Aplicado", 
		"Data de Nascimento"
	having 
		to_date("Data da Venda", 'MM/DD/YYYY') BETWEEN '2024-12-18' AND '2024-12-24'
	order by 
		vendas_acumuladas  desc
	)

select 	
	"Nome do Cliente", 
	extract(year from AGE(to_date("Data de Nascimento", 'YYYY-MM-DD'))) AS idade, 
	SUM(("Quantidade" * "Preço Unitário") - "Desconto Aplicado") as Vendas_Acumuladas
FROM 
	semana_passada
group by 
	"Nome do Cliente", 
	"Data de Nascimento"
order by 
	Vendas_Acumuladas desc
limit 1

--7) Produto mais vendido na semana pré natal
with semana_passada as(
	select 	
		"Produto",
		"Quantidade"
	from 
		raw_data 
	group by 
		"Produto", 
		"Data da Venda", 
		"Quantidade"
	HAVING 
		to_date("Data da Venda", 'MM/DD/YYYY') BETWEEN '2024-12-18' AND '2024-12-24'
	)

select 	
	distinct("Produto") as Produto,
	SUM("Quantidade") as qtd_vendida	
FROM 
	semana_passada
group by 
	Produto
order by 
	qtd_vendida DESC
limit 1