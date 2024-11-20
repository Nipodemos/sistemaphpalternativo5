import { RecordId } from 'surrealdb';
import { getDb, initDb } from './connection';
import type { Cidade, Estado, Tela } from './types';

type retornoApiCidade = {
	codigo_ibge: string;
	nome: string;
};
type retornoApiEstado = {
	id: number;
	sigla: string;
	nome: string;
};

async function main() {
	await initDb();
	const db = getDb();
	if (db === undefined) {
		throw new Error('sem conexão com o banco de dados');
	}
	const token = await db.signin({
		username: 'root',
		password: 'root'
	});

	if (!token) {
		throw new Error('nao consegiui logar');
	}

	// criando tabela de telas
	const telas = [
		{
			menu: 'Clientes',
			submenu: 'Cadastro de clientes',
			id: 'cliente',
			icone: 'fa fa-user',
			url: '/admin/cliente/listar_cliente'
		},
		{
			menu: 'CRM',
			submenu: 'Agenda',
			id: 'agenda',
			icone: 'fa fa-calendar',
			url: '/admin/crm/listar_agenda'
		},
		{
			menu: 'Tabelas básicas',
			submenu: 'Cadastro de empresa',
			id: 'empresa',
			icone: 'fa fa-calendar',
			url: '/admin/empresa/listar_empresa'
		},
		{
			menu: 'Tabelas básicas',
			submenu: 'Cadastro de funcionário',
			id: 'funcionario',
			icone: 'fa fa-calendar',
			url: '/admin/funcionario/listar_funcionario'
		},
		{
			menu: 'Usuários',
			submenu: 'Cadastro de usuários',
			id: 'usuario',
			icone: 'fa fa-user',
			url: '/admin/usuario/listar_usuario'
		},
		{
			menu: 'Usuários',
			submenu: 'Permissões de tela',
			id: 'permissaoTela',
			icone: 'fa fa-user',
			url: '/admin/permissao/listar_permissao'
		}
	];

	for (const tela of telas) {
		console.log('tela: ', tela.submenu);
		// const resultado = await db.upsert(new RecordId('tela', tela.id), tela);
		// console.log('resultado :>> ', resultado);
		const telaExiste: undefined | Tela = await db.select<Tela>(new RecordId('tela', tela.id));

		if (!telaExiste) {
			const resultInsert = await db.insert('tela', tela);
			if (!resultInsert) {
				throw new Error('    Erro ao inserir tela: ' + tela.submenu);
			}
			console.log('    tela inserida com sucesso: ' + tela.submenu);
		} else {
			console.log('    tela já existe: ' + tela.submenu);
		}
	}

	const retornoEstados = await fetch('https://brasilapi.com.br/api/ibge/uf/v1');

	console.log('Vai inserir os estados');
	const estados: retornoApiEstado[] = await retornoEstados.json();

	for (const estado of estados) {
		console.log('estado.nome :>> ', estado.nome);

		const estadoExiste: undefined | Estado = await db.select<Estado>(
			new RecordId('estado', estado.sigla)
		);
		// checar se estado existe antes de inserir
		// const [estadoExiste] = await db.query<Estado[][]>(`SELECT * FROM estado:${estado.sigla}`);

		if (!estadoExiste) {
			console.log('    estado não existe, inserindo');
			const resultInsert = await db.insert('estado', {
				id: estado.sigla,
				nome: estado.nome,
				sigla: estado.sigla
			});

			if (!resultInsert) {
				throw new Error('    Erro ao inserir estado');
			}
		} else {
			console.log('    estado já existe');
			continue;
		}
		const retornoCidades = await fetch(
			`https://brasilapi.com.br/api/ibge/municipios/v1/${estado.sigla}?providers=dados-abertos-br,gov,wikipedia`
		);

		console.log('    inserindo cidades');
		const cidades: retornoApiCidade[] = await retornoCidades.json();
		console.log('        ' + cidades.length + ' cidades encontradas');
		for (const cidade of cidades) {
			const cidadeExiste: undefined | Cidade = await db.select<Cidade>(
				new RecordId('cidade', 'id' + cidade.codigo_ibge)
			);
			// console.log('cidadeExiste :>> ', cidadeExiste);
			// checar se cidade existe antes de inserir
			if (cidadeExiste) {
				console.log('        cidade já existe: ' + cidade.nome + ' - ' + cidade.codigo_ibge);
				continue;
			}
			const resultInsert = await db.insert('cidade', {
				id: new RecordId('cidade', 'id' + cidade.codigo_ibge),
				nome: cidade.nome,
				estado: new RecordId('estado', estado.sigla),
				codigoIbge: cidade.codigo_ibge
			});
			if (!resultInsert) {
				throw new Error('        Erro ao inserir cidade');
			} else {
				console.log(
					'        cidade inserida com sucesso: ' + cidade.nome + ' - ' + cidade.codigo_ibge
				);
			}
		}
		console.log('        cidades inseridas com sucesso');
	}
	console.log('Estados inseridos com sucesso');
}

main().then(() => {
	console.log('Seed finalizado');
	process.exit(0);
});
