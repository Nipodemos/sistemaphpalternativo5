import { getDb } from '$lib/database/connection';
import { fail, redirect } from '@sveltejs/kit';
import { message, superValidate } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';
import { z } from 'zod';

const loginSchema = z.object({
	login: z.string().min(3, 'login precisa ter pelo menos 3 caracteres'),
	senha: z.string().min(3, 'senha precisa ter pelo menos 3 caracteres')
});

export const load = async ({ cookies }) => {
	const token = cookies.get('tokenUsuario');
	console.log('token dos cookies :>> ', token);
	if (token) {
		const db = getDb();
		let autenticado = false;
		try {
			autenticado = await db.authenticate(token);
		} catch (error) {
			console.log('error :>> ', error);
			if (error instanceof Error) {
				console.log('error.message :>> ', error.message);
				console.log('error.name :>> ', error.name);
			}
			console.log('token expirou ou deu erro');
		}
		if (autenticado) {
			redirect(303, '/admin');
		}
	}
	const form = await superValidate(zod(loginSchema));

	return { form };
};

export const actions = {
	default: async ({ cookies, request }) => {
		const form = await superValidate(request, zod(loginSchema));
		console.log('form :>> ', form);
		if (!form.valid) {
			return fail(400, { form });
		}

		const login = form.data.login;
		const senha = form.data.senha;

		const db = getDb();
		if (!db) {
			return fail(503, { form, detalhesErro: 'Serviço indisponível temporariamente' });
		}
		try {
			const authenticatedUser = await db.signin({
				namespace: 'test',
				database: 'test',
				access: 'conta_usuario',
				variables: {
					login,
					senha
				}
			});
			console.log({ authenticatedUser });
			cookies.set('tokenUsuario', authenticatedUser, {
				// send cookie for every page
				path: '/',
				// server side only cookie so you can't use `document.cookie`
				httpOnly: true,
				// only requests from same site can send cookies
				// https://developer.mozilla.org/en-US/docs/Glossary/CSRF
				sameSite: 'strict',
				// only sent over HTTPS in production
				secure: process.env.NODE_ENV === 'production',
				// set cookie to expire after one day
				maxAge: 60 * 60 * 24
			});
			return message(form, 'Logado com sucesso!!');
		} catch (error) {
			console.log('usuário não existe');
			// console.log('error :>> ', error);
			if (error instanceof Error) {
				console.log('error cause :>> ', error.cause);
				console.log('error message :>> ', error.message);
				console.log('error name :>> ', error.name);
				return fail(503, { form, detalhesErro: 'Login ou senha inválido' });
			}
		}
	}
};
