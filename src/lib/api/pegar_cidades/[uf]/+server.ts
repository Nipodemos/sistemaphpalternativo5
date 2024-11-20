import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

type Cidade = { codigo_ibge: string; nome: string };

export const GET: RequestHandler = async ({ params }) => {
	const uf = params.uf;
	const retorno = await fetch(
		`https://brasilapi.com.br/api/ibge/municipios/v1/${uf}?providers=dados-abertos-br,gov,wikipedia`
	);

	const cidades: Cidade[] = await retorno.json();

	console.log('params :>> ', params);

	return json(cidades);
};
