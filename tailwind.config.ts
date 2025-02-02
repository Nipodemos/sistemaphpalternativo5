import forms from '@tailwindcss/forms';
import type { Config } from 'tailwindcss';

import { skeleton, contentPath } from '@skeletonlabs/skeleton/plugin';
import * as themes from '@skeletonlabs/skeleton/themes';

export default {
	content: ['./src/**/*.{html,js,svelte,ts}', contentPath(import.meta.url, 'svelte')],
	theme: {
		extend: {}
	},
	plugins: [
		forms,
		skeleton({
			// NOTE: each theme included will be added to your CSS bundle
			themes: [themes.cerberus, themes.rose]
		})
	]
} satisfies Config;
