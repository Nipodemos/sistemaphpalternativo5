import { initDb, DatabaseConnectionError } from '$lib/database/connection';
import { redirect } from '@sveltejs/kit';

export async function handle({ event, resolve }) {
	try {
		await initDb();
		return await resolve(event);
	} catch (error) {
		if (error instanceof DatabaseConnectionError) {
			throw redirect(303, '/');
		}
		throw error;
	}
}
