import { json, type RequestHandler } from '@sveltejs/kit';

type Estado = {
	id: number;
	sigla: string;
	nome: string;
};

export const GET: RequestHandler = async () => {
	const retorno = await fetch('https://brasilapi.com.br/api/ibge/uf/v1');
	// console.log('retorno :>> ', retorno);

	const estados: Estado[] = await retorno.json();
	// console.log('estados :>> ', estados);

	return json(estados);
};
