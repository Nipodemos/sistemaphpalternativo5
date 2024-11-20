<script lang="ts">
	import '../app.css';
	import { superForm } from 'sveltekit-superforms/client';
	import { goto } from '$app/navigation';
	import { getContext } from 'svelte';
	import { type ToastContext } from '@skeletonlabs/skeleton-svelte';
	import type { PageData } from './$types';
	import SuperDebug from 'sveltekit-superforms';
	type Props = {
		data: PageData;
	};

	let { data }: Props = $props();
	export const toast: ToastContext = getContext('toast');

	const { form, errors, enhance, submitting } = superForm(data.form, {
		onResult: ({ result }) => {
			console.log({ result });
			if (result.type === 'success') {
				toast.create({
					title: 'Sucesso',
					description: 'Login realizado com sucesso!',
					type: 'success'
				});
				// Redirect after a short delay
				setTimeout(() => {
					goto('/admin');
				}, 200);
			} else {
				toast.create({
					title: 'Erro',
					description: 'Login ou senha inválidos',
					type: 'error'
				});
			}
		}
	});
</script>

<SuperDebug data={$form} />
<div class="container mx-auto flex h-full items-center justify-center">
	<div
		class="card w-full max-w-sm border-[1px] p-4 text-center border-surface-200-800 preset-filled-surface-100-900"
	>
		<!-- <div class="card w-full max-w-sm p-4"></div> -->
		<h2 class="h2 mb-4">Login</h2>
		<form method="POST" use:enhance>
			<label class="label">
				<span>Email ou login</span>
				<input class="input" type="text" name="login" bind:value={$form.login} />
			</label>
			{#if $errors.login}
				{#each $errors.login as erro}
					<p class="text-error-500">{erro}</p>
				{/each}
			{/if}

			<label class="label mt-4">
				<span>Senha</span>
				<input class="input" type="password" name="senha" bind:value={$form.senha} />
			</label>
			{#if $errors.senha}
				{#each $errors.senha as erro}
					<p class="text-error-500">{erro}</p>
				{/each}
			{/if}

			<button type="submit" class="btn mt-4 w-full preset-filled">
				{#if $submitting}
					<span>
						<i class="fas fa-spinner fa-spin"></i>
					</span>
				{/if}
				<span>Login</span>
			</button>
		</form>
	</div>
</div>
