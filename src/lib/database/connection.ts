import { Surreal } from 'surrealdb';

let db: Surreal | undefined;

export class DatabaseConnectionError extends Error {
	constructor(message: string) {
		super(message);
		this.name = 'DatabaseConnectionError';
	}
}

export async function initDb(): Promise<void> {
	if (db) return;
	db = new Surreal();
	const tentativas = 3;
	for (let i = 0; i < tentativas; i++) {
		try {
			await db.connect('http://127.0.0.1:8000/rpc');
			await db.use({ namespace: 'test', database: 'test' });
		} catch (err) {
			await new Promise((resolve) => setTimeout(resolve, 500));
			console.error('Failed to connect to SurrealDB:', err);
		}
	}
	throw new DatabaseConnectionError('Failed to connect to the database after multiple attempts');
}

export async function closeDb(): Promise<void> {
	if (!db) return;
	await db.close();
	db = undefined;
}

export function getDb(): Surreal {
	if (!db) {
		throw new DatabaseConnectionError('Database connection not initialized');
	}
	return db;
}
