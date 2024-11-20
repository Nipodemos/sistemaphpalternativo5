import type { RecordId } from 'surrealdb';

export interface BaseTabela {
	id: RecordId;
	[x: string]: unknown;
	criadoEm: Date;
	atualizadoEm: Date;
	canceladoEm: Date | null;
}

export interface Tela extends BaseTabela {
	menu: string;
	submenu: string;
	codigo: string;
	icone: string;
	url: string;
}

export interface PermissaoTela extends BaseTabela {
	funcionario: Funcionario;
	tela: Tela;
	podeVisualizar: boolean;
	podeCriar: boolean;
	podeEditar: boolean;
	podeDeletar: boolean;
	podeGerarRelatorio: boolean;
}

export interface Funcionario extends BaseTabela {
	nome: string;
	cpfcnpj: string;
	pessoa: string;
	nascimento: Date;
	enderecoCompleto: EnderecoCompleto;
	permissoesTela: PermissaoTela[];
}

export interface Estado extends BaseTabela {
	nome: string;
	sigla: string;
	cidades: Cidade[];
}
export interface Cidade extends BaseTabela {
	nome: string;
	estado: Estado;
	codigoIbge: string;
}

export interface Fornecedor extends BaseTabela {
	// A FAZER
	A_FAZER: string;
}

export interface Empresa extends BaseTabela {
	// A FAZER
	A_FAZER: string;
}

export interface Cliente extends BaseTabela {
	// A FAZER
	A_FAZER: string;
}

export interface EnderecoCompleto extends BaseTabela {
	dono: Fornecedor | Empresa | Cliente | Funcionario;
	rua: string;
	numero: string;
	complemento?: string;
	bairro: string;
	cidade: Cidade;
	estado: Estado;
	cep: string;
}
