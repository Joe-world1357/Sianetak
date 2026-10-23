import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  { ignores: ['dist/**', 'coverage/**', 'node_modules/**', '*.js', '**/*.config.js'] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      // Never log through console directly; use the Nest Logger so redaction rules apply.
      'no-console': 'error',
    },
  },
  {
    files: ['src/scripts/**/*.ts', 'src/database/seeds/run-seed.ts'],
    rules: { 'no-console': 'off' },
  },
);
