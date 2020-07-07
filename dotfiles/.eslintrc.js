module.exports = {
  env: {
    browser: true,
    es6: true,
  },
  plugins: ['@typescript-eslint'],
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended', 'prettier/@typescript-eslint', ],
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  // overrides: [
  //   {
  //     files: ['*.svelte'],
  //     processor: 'svelte3/svelte3'
  //   }
  // ],
  rules: {},
}
