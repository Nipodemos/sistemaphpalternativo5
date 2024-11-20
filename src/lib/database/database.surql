
DEFINE ACCESS conta_usuario ON DATABASE TYPE RECORD
	SIGNUP (
		CREATE usuario SET
			email = $email,
			empresa = $empresa,
			funcionario = $funcionario,
			login = $login,
			senha = crypto::argon2::generate($senha)
	)
	SIGNIN (
		SELECT * FROM usuario WHERE (email = $login || login = $login ) AND crypto::argon2::compare(senha, $senha)
	)
	DURATION FOR TOKEN 10h, FOR SESSION 10h;


DEFINE TABLE estado SCHEMAFULL CHANGEFEED 30d
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE,DELETE FULL
;
DEFINE FIELD OVERWRITE nome									ON estado TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE sigla								ON estado TYPE string ASSERT string::len($value) == 2;
DEFINE FIELD OVERWRITE cidades 							ON estado VALUE <future> {
	let $estado = id;
	RETURN (SELECT * FROM cidade WHERE estado = $estado)
};
DEFINE FIELD OVERWRITE criadoEm 						ON estado TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON estado TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm 				ON estado TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;

DEFINE INDEX uf_unico ON estado FIELDS sigla UNIQUE;

DEFINE TABLE cidade SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE,DELETE FULL
;
DEFINE FIELD OVERWRITE nome									ON cidade TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE estado								ON cidade TYPE record<estado> ;
DEFINE FIELD OVERWRITE codigoIbge						ON cidade TYPE string ASSERT string::len($value) == 7;
DEFINE FIELD OVERWRITE criadoEm 						ON cidade TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON cidade TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm 				ON cidade TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;

DEFINE INDEX codigoIbge 					ON cidade FIELDS codigoIbge UNIQUE;
DEFINE INDEX unicidadeestadocidade		ON cidade FIELDS nome,estado UNIQUE;

DEFINE TABLE enderecoCompleto SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE dono									ON enderecoCompleto TYPE record;
DEFINE FIELD OVERWRITE rua									ON enderecoCompleto TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE numero								ON enderecoCompleto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE complemento					ON enderecoCompleto TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE bairro								ON enderecoCompleto TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE cidade								ON enderecoCompleto TYPE record<cidade>;
DEFINE FIELD OVERWRITE estado								ON enderecoCompleto TYPE record<estado>;
DEFINE FIELD OVERWRITE cep									ON enderecoCompleto TYPE string ASSERT string::len($value) == 8;
DEFINE FIELD OVERWRITE criadoEm 						ON enderecoCompleto TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON enderecoCompleto TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm 				ON enderecoCompleto TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;

define table fornecedor schemafull
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE nome									ON fornecedor TYPE string ASSERT string::len($value) > 1 && string::len($value) < 256;
DEFINE FIELD OVERWRITE fantasia							ON fornecedor TYPE string ASSERT string::len($value) > 1 && string::len($value) < 256;
DEFINE FIELD OVERWRITE codigo								ON fornecedor TYPE int READONLY DEFAULT {
		LET $max_codigo = ((select value codigo from fornecedor order by codigo desc limit 1)[0] || 0);
		RETURN $max_codigo+1;
};
DEFINE FIELD OVERWRITE cpfcnpj							ON fornecedor TYPE string ASSERT	string::len($value) == 14 || string::len($value) == 18;
DEFINE FIELD OVERWRITE pessoa								ON fornecedor TYPE string ASSERT string::contains($value, "F") || string::contains($value, "J");
DEFINE FIELD OVERWRITE inscricaoEstadual		ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE enderecoCompleto			ON fornecedor VALUE <future> {
	let $fornecedor = id;
	RETURN (SELECT * FROM enderecoCompleto WHERE dono = $fornecedor)
};
DEFINE FIELD OVERWRITE telefone1						ON fornecedor TYPE string ASSERT string::len($value) > 1;
DEFINE FIELD OVERWRITE telefone2						ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE email								ON fornecedor TYPE string | null DEFAULT null ASSERT string::is::email($value) || $value == null;
DEFINE FIELD OVERWRITE observacao						ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE responsavelNome			ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE responsavelEmail			ON fornecedor TYPE string | null DEFAULT null ASSERT string::is::email($value) || $value == null;
DEFINE FIELD OVERWRITE responsavelTelefone	ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE parceiro							ON fornecedor TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE site									ON fornecedor TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE criadoEm							ON fornecedor TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON fornecedor TYPE datetime| null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON fornecedor TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX codigo_index					ON fornecedor FIELDS codigo UNIQUE;
DEFINE INDEX cpfcnpj_index				ON fornecedor FIELDS cpfcnpj UNIQUE;

DEFINE TABLE produtoCategoria SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE tabela								ON produtoCategoria TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE grupo								ON produtoCategoria TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE subgrupo							ON produtoCategoria TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE criadoEm							ON produtoCategoria TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON produtoCategoria TYPE datetime| null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON produtoCategoria TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE comissao							ON produtoCategoria TYPE number ASSERT $value >= 0 && $value <= 1 DEFAULT 0;
DEFINE INDEX produtoCategoriaUnico ON produtoCategoria FIELDS tabela, grupo, subgrupo UNIQUE;

DEFINE TABLE produto SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE fornecedor						ON produto TYPE record<fornecedor> ;
DEFINE FIELD OVERWRITE descricao						ON produto TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE unidade							ON produto TYPE string ASSERT string::len($value) > 1;
DEFINE FIELD OVERWRITE produtoCategoria			ON produto TYPE record<produtoCategoria> ;
DEFINE FIELD OVERWRITE ativo								ON produto TYPE bool DEFAULT true;
DEFINE FIELD OVERWRITE precoCompraAprovar		ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE precoCompraAprovado	ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE precoVendaAprovar		ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE precoVendaAprovado		ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE precoCustoAprovar		ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE precoCustoAprovado		ON produto TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE descontoMaximo				ON produto TYPE number ASSERT $value >= 0 && $value <= 1 DEFAULT 0;
DEFINE FIELD OVERWRITE comissao							ON produto TYPE number ASSERT $value >= 0 && $value <= 1 DEFAULT 0;
DEFINE FIELD OVERWRITE comissaoGerente			ON produto TYPE number ASSERT $value >= 0 && $value <= 1 DEFAULT 0;
DEFINE FIELD OVERWRITE mix									ON produto TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE codigoBarra					ON produto TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE codigo								ON produto TYPE number READONLY DEFAULT {
	LET $max_codigo = (select value codigo from produto order by codigo desc limit 1)[0] || 0;
	RETURN $max_codigo+1;
};
DEFINE FIELD OVERWRITE grade								ON produto TYPE array<record<produtoGrade>> DEFAULT [];
DEFINE FIELD OVERWRITE criadoEm							ON produto TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON produto TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON produto TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX codigo_index					ON produto FIELDS codigo UNIQUE;
DEFINE INDEX descricao_index 			ON produto FIELDS descricao UNIQUE;


DEFINE TABLE acabamento SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE descricao						ON acabamento TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE criadoEm							ON acabamento TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON acabamento TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON acabamento TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE codigo								ON acabamento TYPE number READONLY DEFAULT {
	LET $max_codigo = (select value codigo from acabamento order by codigo desc limit 1)[0] || 0;
	RETURN $max_codigo+1;
};
DEFINE INDEX descricao_index 			ON acabamento FIELDS descricao UNIQUE;
DEFINE INDEX codigo_index					ON acabamento FIELDS codigo UNIQUE;


DEFINE TABLE cor SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE descricao						ON cor TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE criadoEm							ON cor TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON cor TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON cor TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE codigo								ON cor TYPE number READONLY DEFAULT {
	LET $max_codigo = (select value codigo from cor order by codigo desc limit 1)[0] || 0;
	RETURN $max_codigo+1;
};
DEFINE INDEX descricao_index 			ON cor FIELDS descricao UNIQUE;
DEFINE INDEX codigo_index					ON cor FIELDS codigo UNIQUE;


DEFINE TABLE produtoGrade SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE NONE
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE produto							ON produtoGrade TYPE record<produto> ;
DEFINE FIELD OVERWRITE cor									ON produtoGrade TYPE record<cor> ;
DEFINE FIELD OVERWRITE acabamento						ON produtoGrade TYPE record<acabamento> | null;
DEFINE FIELD OVERWRITE ativo								ON produtoGrade TYPE bool DEFAULT true;
DEFINE FIELD OVERWRITE criadoEm							ON produtoGrade TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON produtoGrade TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON produtoGrade TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX produtoGrade_index 	ON produtoGrade FIELDS produto,cor,acabamento UNIQUE;


DEFINE TABLE empresa SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE NONE
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE nome									ON empresa TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE codigo								ON cor TYPE number READONLY DEFAULT {
	LET $max_codigo = (select value codigo from cor order by codigo desc limit 1)[0] || 0;
	RETURN $max_codigo+1;
};
DEFINE FIELD OVERWRITE fantasia							ON empresa TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE cnpj									ON empresa TYPE string ASSERT string::len($value) == 18;
DEFINE FIELD OVERWRITE inscricaoEstadual		ON empresa TYPE string | null;
DEFINE FIELD OVERWRITE enderecoCompleto			ON empresa VALUE <future> {
	let $empresa = id;
	RETURN (SELECT * FROM enderecoCompleto WHERE dono = $empresa)
};
DEFINE FIELD OVERWRITE telefone1						ON empresa TYPE string ASSERT string::len($value) > 1;
DEFINE FIELD OVERWRITE telefone2						ON empresa TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE email								ON empresa TYPE string | null ASSERT $value == null || string::is::email($value) DEFAULT null;
DEFINE FIELD OVERWRITE criadoEm							ON empresa TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON empresa TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON empresa TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX codigo ON empresa FIELDS codigo UNIQUE;
DEFINE INDEX cnpj 	ON empresa FIELDS cnpj UNIQUE;


DEFINE TABLE cliente SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE nome									ON cliente TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE fantasia							ON cliente TYPE string ASSERT string::len($value) > 2 || $value == null DEFAULT null;
DEFINE FIELD OVERWRITE cpfcnpj							ON cliente TYPE string ASSERT string::len($value) == 14 || string::len($value) == 18;
DEFINE FIELD OVERWRITE pessoa								ON cliente TYPE string ASSERT string::contains($value, "F") || string::contains($value, "J");
DEFINE FIELD OVERWRITE nascimento						ON cliente TYPE datetime ASSERT type::is::datetime(type::datetime($value));
DEFINE FIELD OVERWRITE inscricaoEstadual		ON cliente TYPE string | null ASSERT string::len($value) < 20 || $value == null DEFAULT null;
DEFINE FIELD OVERWRITE enderecoCompleto			ON cliente VALUE <future> {
	let $cliente = id;
	RETURN (SELECT * FROM enderecoCompleto WHERE dono = $cliente)
};
DEFINE FIELD OVERWRITE telefone1						ON cliente TYPE string ASSERT string::len($value) == 16 || string::len($value) == 14;
DEFINE FIELD OVERWRITE telefone2						ON cliente TYPE string | null ASSERT type::is::null($value) || string::len($value) == 16 || string::len($value) == 14 DEFAULT null;
DEFINE FIELD OVERWRITE email								ON cliente TYPE string | null ASSERT type::is::null($value) || string::is::email($value);
DEFINE FIELD OVERWRITE criadoEm							ON cliente TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON cliente TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON cliente TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX index_cpfcnpj 			ON produto FIELDS cpfcnpj UNIQUE;


DEFINE TABLE funcionario SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE nome									ON funcionario TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE cpfcnpj							ON funcionario TYPE string ASSERT string::len($value) == 14;
DEFINE FIELD OVERWRITE pessoa								ON funcionario TYPE string ASSERT $value INSIDE ['F','J'];
DEFINE FIELD OVERWRITE nascimento						ON funcionario TYPE datetime;
DEFINE FIELD OVERWRITE enderecoCompleto			ON funcionario VALUE <future> {
	let $funcionario = id;
	RETURN (SELECT * FROM enderecoCompleto WHERE dono = $funcionario)
};
DEFINE FIELD OVERWRITE permissoesTela 			ON funcionario VALUE <future> {
	let $funcionario = id;
	RETURN (SELECT * FROM permissaoTela WHERE funcionario = $funcionario)
};
DEFINE FIELD OVERWRITE telefone1						ON funcionario TYPE string ASSERT string::len($value) > 1;
DEFINE FIELD OVERWRITE telefone2						ON funcionario TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE email								ON funcionario TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE apelido							ON funcionario TYPE string | null DEFAULT null;
DEFINE FIELD OVERWRITE comissao							ON funcionario TYPE number ASSERT $value >= 0 && $value <= 1;
DEFINE FIELD OVERWRITE nivelPermissao				ON funcionario TYPE number ASSERT $value > 0;
DEFINE FIELD OVERWRITE admitidoEm						ON funcionario TYPE datetime;
DEFINE FIELD OVERWRITE demitidoEm						ON funcionario TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE criadoEm							ON funcionario TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON funcionario TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON funcionario TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE INDEX OVERWRITE index_cnpjcpf 			ON funcionario FIELDS cpfcnpj UNIQUE;

DEFINE TABLE pedidoVenda SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE empresa							ON pedidoVenda TYPE record<empresa> ;
DEFINE FIELD OVERWRITE cliente							ON pedidoVenda TYPE record<cliente> ;
DEFINE FIELD OVERWRITE produtoGrade					ON pedidoVenda TYPE record<produtoGrade> ;
DEFINE FIELD OVERWRITE funcionario					ON pedidoVenda TYPE record<funcionario> ;
DEFINE FIELD OVERWRITE dataPedido						ON pedidoVenda TYPE datetime;
DEFINE FIELD OVERWRITE dataEntrega					ON pedidoVenda TYPE datetime;
DEFINE FIELD OVERWRITE observacao						ON pedidoVenda TYPE string;
DEFINE FIELD OVERWRITE criadoEm							ON pedidoVenda TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON pedidoVenda TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON pedidoVenda TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;


DEFINE TABLE crmCategoria SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE descricao						ON crmCategoria TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE corTexto							ON crmCategoria TYPE record<cor> ;
DEFINE FIELD OVERWRITE corFundo							ON crmCategoria TYPE record<cor> ;
DEFINE FIELD OVERWRITE criadoEm							ON crmCategoria TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE atualizadoEm					ON crmCategoria TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON crmCategoria TYPE datetime | null DEFAULT null;


DEFINE TABLE crm SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE empresa							ON crm TYPE record<empresa> ;
DEFINE FIELD OVERWRITE cliente							ON crm TYPE record<cliente> ;
DEFINE FIELD OVERWRITE categoria						ON crm TYPE record<crmCategoria> ;
DEFINE FIELD OVERWRITE funcionario					ON crm TYPE record<funcionario> ;
DEFINE FIELD OVERWRITE dataAgendada					ON crm TYPE datetime ASSERT type::is::datetime(type::datetime($value));
DEFINE FIELD OVERWRITE dataRealizada				ON crm TYPE datetime;
DEFINE FIELD OVERWRITE criadoEm							ON crm TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON crm TYPE datetime | null DEFAULT null;
DEFINE FIELD OVERWRITE atualizadoEm					ON crm TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;


DEFINE TABLE crmObservacoes SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD OVERWRITE crm									ON crmObservacoes TYPE record<crm> ;
DEFINE FIELD OVERWRITE descricao						ON crmObservacoes TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE categoriaAntes				ON crmObservacoes TYPE record<crmCategoria>;
DEFINE FIELD OVERWRITE categoriaDepois			ON crmObservacoes TYPE record<crmCategoria>;
DEFINE FIELD OVERWRITE criadoEm							ON crmObservacoes TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE atualizadoEm					ON crmObservacoes TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm					ON crmObservacoes TYPE datetime | null DEFAULT null;


DEFINE TABLE usuario SCHEMAFULL 
PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE;

DEFINE FIELD OVERWRITE email 								ON usuario TYPE string | null ASSERT string::is::email($value) || $value == null;
//DEFINE FIELD OVERWRITE empresa 							ON usuario TYPE record<empresa> ;
DEFINE FIELD OVERWRITE funcionario 					ON usuario TYPE record<funcionario>;
DEFINE FIELD OVERWRITE login								ON usuario TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE senha 								ON usuario TYPE string ASSERT string::len($value) > 6;
REMOVE FIELD nivelPermissao									ON usuario;
DEFINE FIELD OVERWRITE criadoEm 						ON usuario TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE atualizadoEm 				ON usuario TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON usuario TYPE datetime | null DEFAULT null;

DEFINE INDEX login_unico ON usuario FIELDS login UNIQUE;

DEFINE TABLE tela SCHEMAFULL
	PERMISSIONS
		FOR SELECT, UPDATE FULL
		FOR CREATE, DELETE NONE
;
DEFINE FIELD OVERWRITE menu									ON tela TYPE string ASSERT string::len($value) >= 2;
DEFINE FIELD OVERWRITE submenu							ON tela TYPE string ASSERT string::len($value) >= 2;
DEFINE FIELD OVERWRITE icone								ON tela TYPE string ASSERT string::len($value) > 2;
DEFINE FIELD OVERWRITE url									ON tela TYPE string;
DEFINE FIELD OVERWRITE criadoEm 						ON tela TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE atualizadoEm 				ON tela TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON tela TYPE datetime | null DEFAULT null;

DEFINE INDEX submenu_unico ON tela FIELDS submenu UNIQUE;

DEFINE TABLE permissaoTela SCHEMAFULL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
//DEFINE FIELD OVERWRITE usuario							ON permissaoTela TYPE record<usuario>;
DEFINE FIELD OVERWRITE funcionario					ON permissaoTela TYPE record<funcionario>;
DEFINE FIELD OVERWRITE tela									ON permissaoTela TYPE record<tela>;
//DEFINE FIELD OVERWRITE permissao						ON permissaoTela TYPE string ASSERT $value INSIDE ['visualizar','criar','editar','deletar','relatorio'];
//DEFINE FIELD OVERWRITE permissoes 					ON permissaoTela TYPE array<'visualizar' | 'criar' | 'editar' | 'deletar' | 'relatorio'>;
DEFINE FIELD OVERWRITE permissoesExtras			ON permissaoTela TYPE string | NULL DEFAULT null;
DEFINE FIELD OVERWRITE podeVisualizar				ON permissaoTela TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE podeCriar						ON permissaoTela TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE podeEditar						ON permissaoTela TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE podeDeletar					ON permissaoTela TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE podeGerarRelatorio		ON permissaoTela TYPE bool DEFAULT false;
DEFINE FIELD OVERWRITE criadoEm 						ON permissaoTela TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE atualizadoEm 				ON permissaoTela TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD OVERWRITE canceladoEm 					ON permissaoTela TYPE datetime | null DEFAULT null;

REMOVE FIELD usuario ON permissaoTela;
REMOVE FIELD permissao ON permissaoTela;
REMOVE FIELD permissoes ON permissaoTela;
REMOVE FIELD permissoes[*] ON permissaoTela;
DEFINE INDEX usuario_tela_unico ON permissaoTela FIELDS usuario,tela,permissao UNIQUE;

DEFINE TABLE movimentacaoEstoque SCHEMAFULL TYPE NORMAL
	PERMISSIONS
		FOR SELECT,CREATE,UPDATE FULL
		FOR DELETE NONE
;
DEFINE FIELD produtoAcabamento		ON movimentacaoEstoque TYPE record<produtoAcabamento>;
DEFINE FIELD quantidade						ON movimentacaoEstoque TYPE number ASSERT $value != 0;
DEFINE FIELD tipoMovimento				ON movimentacaoEstoque TYPE string ASSERT $value INSIDE ['venda','compra','ajuste'];
DEFINE FIELD statusMovimento		 	ON movimentacaoEstoque TYPE string ASSERT $value INSIDE ['ok','encomendado','reservado','defeito','pendente'];
DEFINE FIELD pedido						 		ON movimentacaoEstoque TYPE record;
DEFINE FIELD criadoEm 						ON movimentacaoEstoque TYPE datetime VALUE $before OR time::now() DEFAULT time::now() READONLY;
DEFINE FIELD atualizadoEm 				ON movimentacaoEstoque TYPE datetime VALUE time::now() DEFAULT time::now() READONLY;
DEFINE FIELD canceladoEm 					ON movimentacaoEstoque TYPE datetime | null DEFAULT null;






